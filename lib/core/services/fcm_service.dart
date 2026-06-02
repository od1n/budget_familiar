import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'supabase_service.dart';

// Importación condicional: firebase_messaging solo compila en Android/iOS.
// En Windows/Linux el paquete está en pubspec pero sin implementación nativa,
// por lo que sus llamadas lanzan UnsupportedError.
// Todos los accesos se envuelven en _isMobile (ver abajo).
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:firebase_messaging/firebase_messaging.dart';

final _log = Logger();

/// `true` en Android e iOS. `false` en Windows, Linux, macOS.
bool get _isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

// ── Manejador de mensajes en background ──────────────────────────────────────
// Debe ser top-level (no puede ser un método de instancia).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(dynamic message) async {
  // El sistema ya muestra la notificación automáticamente cuando la app
  // está cerrada o en background; aquí solo logueamos.
  _log.d('FCM background: ${message.notification?.title}');
}

// ── FcmService ────────────────────────────────────────────────────────────────

/// Gestiona el ciclo de vida de Firebase Cloud Messaging.
///
/// Solo se inicializa en Android/iOS. En Windows/Linux es un no-op completo.
///
/// Flujo:
/// 1. `initialize()` — solicita permisos y registra handlers.
/// 2. `registerToken(groupId)` — sube el FCM token a Supabase via RPC.
/// 3. `revokeToken()` — elimina el token al cerrar sesión.
/// 4. `sendGroupPush(...)` — llama la Edge Function `send-push`.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  String? _currentToken;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (!_isMobile) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // Solicitar permisos (iOS requiere diálogo explícito)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Handler para mensajes recibidos con la app en background/terminada
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Handler para mensajes con la app en primer plano
      FirebaseMessaging.onMessage.listen((msg) {
        final notif = msg.notification;
        if (notif != null) {
          _log.i('FCM foreground: ${notif.title} — ${notif.body}');
          // La notificación local la muestra NotificationService si está activo.
          // Aquí podría dispararse adicionalmente, pero el SnackBar de
          // AdaptiveScaffold ya cubre este caso para alertas de presupuesto.
        }
      });

      _log.i('FcmService: inicializado');
    } catch (e) {
      _log.w('FcmService: error en initialize: $e');
    }
  }

  // ── Registro de token ─────────────────────────────────────────────────────

  /// Obtiene el FCM token del dispositivo y lo registra en Supabase.
  /// Llamar después de que el usuario haga login y tenga groupId.
  Future<void> registerToken(String groupId) async {
    if (!_isMobile || groupId.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null) {
        _log.w('FcmService: token FCM nulo');
        return;
      }
      _currentToken = token;

      await supabase.rpc('upsert_fcm_token', params: {
        'p_group_id': groupId,
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      });

      _log.i('FcmService: token registrado para group=$groupId');

      // Escuchar refreshes del token
      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        supabase.rpc('upsert_fcm_token', params: {
          'p_group_id': groupId,
          'p_token': newToken,
          'p_platform': Platform.isIOS ? 'ios' : 'android',
        }).catchError((e) => _log.w('FcmService: token refresh error: $e'));
      });
    } catch (e) {
      _log.w('FcmService: error en registerToken: $e');
    }
  }

  // ── Revocar token ─────────────────────────────────────────────────────────

  /// Elimina el token del dispositivo de Supabase al cerrar sesión.
  Future<void> revokeToken() async {
    if (!_isMobile || _currentToken == null) return;
    try {
      await supabase.rpc('delete_fcm_token', params: {'p_token': _currentToken});
      _currentToken = null;
      _log.i('FcmService: token revocado');
    } catch (e) {
      _log.w('FcmService: error en revokeToken: $e');
    }
  }

  // ── Enviar push al grupo ──────────────────────────────────────────────────

  /// Llama a la Edge Function `send-push` para notificar a todos los
  /// dispositivos Android/iOS del grupo (excepto el remitente).
  ///
  /// No-crítico: si falla no interrumpe el flujo principal.
  Future<void> sendGroupPush({
    required String groupId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (groupId.isEmpty) return;
    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.functions.invoke(
        'send-push',
        body: {
          'group_id': groupId,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
          if (userId != null) 'exclude_user_id': userId,
        },
      );
      _log.d('FcmService: push enviado al grupo $groupId');
    } catch (e) {
      _log.w('FcmService: error en sendGroupPush: $e');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService.instance);
