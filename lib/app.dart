import 'dart:async';

import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/services/deeplink_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/realtime_service.dart';
import 'core/services/recurring_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/sync_service.dart';
import 'data/local/app_database.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/family/providers/family_provider.dart';
import 'features/subscription/providers/subscription_provider.dart';
import 'router/app_router.dart';

class BudgetApp extends ConsumerWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Dispara syncDown cada vez que el usuario inicia sesión.
    // ref.listen en build() es seguro: Riverpod gestiona el ciclo de vida
    // del listener y lo cancela si el widget se desmonta.
    ref.listen(authStateChangesProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn ||
            authState.event == AuthChangeEvent.initialSession) {
          // Flujo de inicialización al hacer login.
          ref
              .read(activeGroupIdProvider.notifier)
              .restoreFromPrefs()
              .then((_) async {
            final userId = supabase.auth.currentUser?.id ?? '';
            var groupId = ref.read(activeGroupIdProvider);

            // Descargar membresía familiar desde Supabase.
            // Necesario en dispositivos donde nunca se guardó el grupo
            // (p.ej. primer login en desktop después de crear grupo en móvil).
            final groupIds = await ref
                .read(syncServiceProvider)
                .syncFamilyMembership();

            // Si estamos en modo personal pero el usuario tiene un grupo,
            // activar automáticamente el primero encontrado.
            if ((groupId == userId || groupId.isEmpty) &&
                groupIds.isNotEmpty) {
              groupId = groupIds.first;
              await ref
                  .read(activeGroupIdProvider.notifier)
                  .setGroup(groupId);
            }

            // Refrescar estado de suscripción premium.
            ref.read(subscriptionProvider.notifier).refresh();
            // Sincronizar datos históricos desde Supabase.
            ref.read(syncServiceProvider).syncDown(groupId);
            // Activar suscripción Realtime para actualizaciones en vivo.
            ref.read(realtimeServiceProvider).subscribe(groupId);
            // Registrar token FCM para push notifications (Android/iOS).
            FcmService.instance.registerToken(groupId);
            // Procesar transacciones recurrentes vencidas y notificar.
            ref
                .read(recurringServiceProvider)
                .processOverdue(groupId)
                .then((count) {
              if (count > 0) {
                NotificationService.instance.showRecurringAlert(count);
              }
            });
            // Mostrar resumen mensual una vez por semana (ISO).
            NotificationService.instance.checkAndShowWeeklySummary(
              groupId: groupId,
              db: ref.read(appDatabaseProvider),
            );
            // Pull periódico cada 60s como respaldo del Realtime.
            // Sube pendientes locales y baja cambios del grupo.
            final svc = ref.read(syncServiceProvider);
            ref.read(_syncTimerProvider.notifier).start(groupId, svc);
          });
        } else if (authState.event == AuthChangeEvent.signedOut) {
          ref.read(realtimeServiceProvider).unsubscribe();
          ref.read(subscriptionProvider.notifier).clear();
          ref.read(_syncTimerProvider.notifier).cancel();
          FcmService.instance.revokeToken();
        }
      });
    });

    // Deeplink de invitación → redirigir a la página de familia.
    ref.listen(pendingInviteCodeProvider, (_, next) {
      final code = next.valueOrNull;
      if (code != null) {
        final isLoggedIn =
            ref.read(authStateChangesProvider).valueOrNull?.session != null;
        if (isLoggedIn) {
          router.go(AppRoutes.family);
        }
      }
    });

    // Cambio de grupo activo → reconectar Realtime + re-sync al nuevo grupo.
    ref.listen(activeGroupIdProvider, (prev, next) {
      if (prev != next && next.isNotEmpty) {
        ref.read(realtimeServiceProvider).subscribe(next);
        final svc = ref.read(syncServiceProvider);
        svc.syncDown(next);
        ref.read(_syncTimerProvider.notifier).start(next, svc);
      }
    });

    return MaterialApp.router(
      title: 'Budget Familiar',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      routerConfig: router,
    );
  }

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ).copyWith(
          surface: AppColors.surface,
          error: AppColors.expense,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          foregroundColor: AppColors.textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.expense),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      );

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
        ).copyWith(
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
      );
}

// ── Timer de sincronización periódica ─────────────────────────────────────────

class _SyncTimerNotifier extends StateNotifier<void> {
  _SyncTimerNotifier() : super(null);

  Timer? _timer;

  /// Inicia el ciclo de sync. Recibe [syncService] directamente para evitar
  /// retener un WidgetRef que podría estar disposed cuando el timer dispare.
  void start(String groupId, SyncService syncService) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      syncService.syncPendingTransactions();
      syncService.syncDown(groupId);
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _syncTimerProvider =
    StateNotifierProvider<_SyncTimerNotifier, void>((_) => _SyncTimerNotifier());
