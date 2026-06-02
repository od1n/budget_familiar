import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/deeplink_service.dart';
import 'core/services/dpapi_storage.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'data/local/app_database.dart';
import 'features/family/providers/family_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar window_manager en desktop para persistir tamaño/posición.
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await windowManager.ensureInitialized();
    await _restoreWindowState();
  }

  try {
    // Inicializar Supabase.
    // Las claves se inyectan en tiempo de compilación via --dart-define:
    //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
    // SharedPrefsStorage reemplaza flutter_secure_storage para evitar la
    // dependencia de ATL (atlstr.h) que no está disponible en Windows desktop.
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    // Validación real en tiempo de ejecución — los assert se eliminan en release.
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL y SUPABASE_ANON_KEY deben definirse con --dart-define. '
        'Ejemplo: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    // Almacenamiento seguro de sesión:
    // - Windows: DpapiStorage cifra con CryptProtectData (DPAPI) — solo
    //   descifrable por el mismo usuario de Windows en el mismo equipo.
    //   No requiere ATL ni C++ nativo; usa crypt32.dll vía dart:ffi.
    // - Linux: SharedPrefsStorage (sin alternativa segura sin libsecret).
    // - Android/iOS/macOS: supabase_flutter usa su storage nativo por defecto
    //   (Keystore / Keychain). Se pasa null para activarlo.
    final LocalStorage? storage = switch (defaultTargetPlatform) {
      TargetPlatform.windows => DpapiStorage(),
      TargetPlatform.linux   => SharedPrefsStorage(),
      _                      => null,
    };

    // Inicializar Firebase (solo Android/iOS — sin implementación nativa en Windows/Linux).
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Firebase.initializeApp();
      await FcmService.instance.initialize();
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: FlutterAuthClientOptions(localStorage: storage),
    );

    // Inicializar servicio de notificaciones locales (permisos en móvil).
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();

    // Crear la instancia de la base de datos local (Drift/SQLite).
    final db = AppDatabase();

    // Leer el grupo activo guardado para el usuario actual (si hay sesión).
    // Esto permite que la app arranque directamente en el grupo correcto
    // sin esperar al listener de authStateChanges.
    final String storedGroupId = await _loadStoredGroup();

    // Leer si el usuario ya completó el onboarding.
    final bool onboardingDone = await _loadOnboardingDone();

    // Inicializar AdMob (solo Android/iOS).
    final adSvc = AdService();
    await adSvc.initialize();

    // Inicializar servicio de deeplinks (invitaciones familiares).
    final deeplinkSvc = DeeplinkService();
    await deeplinkSvc.initialize();

    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          groupInitProvider.overrideWithValue(storedGroupId),
          onboardingInitProvider.overrideWithValue(onboardingDone),
          adServiceProvider.overrideWithValue(adSvc),
          deeplinkServiceProvider.overrideWithValue(deeplinkSvc),
        ],
        child: const BudgetApp(),
      ),
    );
  } catch (e, stack) {
    Logger().f('ERROR FATAL EN ARRANQUE', error: e, stackTrace: stack);
    rethrow;
  }
}

// ── Window state ─────────────────────────────────────────────────────────────

const _kWinX = 'win_x';
const _kWinY = 'win_y';
const _kWinW = 'win_w';
const _kWinH = 'win_h';
const _kWinMax = 'win_max';

/// Aplica el tamaño y posición guardados, o valores por defecto.
Future<void> _restoreWindowState() async {
  final prefs = await SharedPreferences.getInstance();
  final w = prefs.getDouble(_kWinW) ?? 1200;
  final h = prefs.getDouble(_kWinH) ?? 800;
  final x = prefs.getDouble(_kWinX);
  final y = prefs.getDouble(_kWinY);
  final isMax = prefs.getBool(_kWinMax) ?? false;

  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(w, h),
      minimumSize: const Size(800, 600),
      center: x == null,
      titleBarStyle: TitleBarStyle.normal,
    ),
    () async {
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
      if (isMax) {
        await windowManager.maximize();
      } else {
        await windowManager.show();
      }
      await windowManager.focus();
    },
  );

  windowManager.addListener(_WindowStateListener());
}

/// Guarda posición, tamaño y estado maximizado cuando el usuario mueve o
/// redimensiona la ventana.
class _WindowStateListener extends WindowListener {
  @override
  void onWindowResized() => _save();

  @override
  void onWindowMoved() => _save();

  @override
  void onWindowMaximize() => _saveMax(true);

  @override
  void onWindowUnmaximize() => _saveMax(false);

  Future<void> _save() async {
    // No guardar si está maximizada — se perdería el tamaño normal.
    if (await windowManager.isMaximized()) return;
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kWinW, size.width);
    await prefs.setDouble(_kWinH, size.height);
    await prefs.setDouble(_kWinX, pos.dx);
    await prefs.setDouble(_kWinY, pos.dy);
  }

  Future<void> _saveMax(bool maximized) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWinMax, maximized);
  }
}

// ── Misc ──────────────────────────────────────────────────────────────────────

/// Lee el grupo guardado para el usuario actual desde SharedPreferences.
/// Devuelve '' si no hay sesión o no hay grupo guardado.
Future<String> _loadStoredGroup() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_group_$userId') ?? '';
  } catch (_) {
    return '';
  }
}

/// Lee si el usuario ya completó el onboarding.
Future<bool> _loadOnboardingDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  } catch (_) {
    return false;
  }
}
