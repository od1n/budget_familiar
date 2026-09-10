import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';
import '../features/budgets/presentation/pages/budgets_page.dart';
import '../features/envelopes/presentation/pages/envelopes_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/family/presentation/pages/family_page.dart';
import '../features/accounts/presentation/pages/accounts_page.dart';
import '../features/recurring/presentation/pages/recurring_transactions_page.dart';
import '../features/agenda/presentation/pages/agenda_page.dart';
import '../features/projections/presentation/pages/projection_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/subscription/presentation/pages/paywall_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../shared/widgets/layout/adaptive_scaffold.dart';

part 'app_router.g.dart';

/// Valor inicial leído desde SharedPreferences en main.dart antes de montar
/// el árbol de widgets. Se sobreescribe con overrideWithValue().
final onboardingInitProvider = Provider<bool>((_) => false);

/// Estado mutable del onboarding — se actualiza desde OnboardingPage.
/// Inicializado con el valor persistido.
final onboardingDoneProvider = StateProvider<bool>(
  (ref) => ref.watch(onboardingInitProvider),
);

/// ChangeNotifier mínimo que permite a GoRouter revaluar el redirect
/// sin destruir ni recrear la instancia del router.
class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const budgets = '/budgets';
  static const envelopes  = '/envelopes';
  static const savings = '/savings';
  static const family = '/family';
  static const accounts = '/accounts';
  static const recurring = '/recurring';
  static const agenda = '/agenda';
  static const projection = '/projection';
  static const settings = '/settings';
  static const paywall = '/paywall';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // El router se crea una sola vez. refreshListenable notifica a GoRouter
  // que debe re-evaluar el redirect sin destruir ni recrear la instancia.
  final notifier = _AuthNotifier();

  ref.listen(authStateChangesProvider, (_, __) => notifier.notify());
  ref.listen(onboardingDoneProvider, (_, __) => notifier.notify());

  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final isLoggedIn = authAsync.valueOrNull?.session != null;
      final onboardingDone = ref.read(onboardingDoneProvider);
      final loc = state.matchedLocation;
      final isOnboarding = loc == AppRoutes.onboarding;
      final isAuthRoute = loc.startsWith('/auth');

      // Usuario autenticado: saltar onboarding y auth
      if (isLoggedIn && (isAuthRoute || isOnboarding)) {
        return AppRoutes.dashboard;
      }
      // No autenticado: mostrar onboarding si no lo ha completado
      if (!isLoggedIn && !onboardingDone && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      // No autenticado + onboarding completado: redirigir rutas protegidas a login
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: OnboardingPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        pageBuilder: (_, __) => const NoTransitionPage(child: PaywallPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, __) => const NoTransitionPage(child: RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.agenda,
        pageBuilder: (_, __) => const NoTransitionPage(child: AgendaPage()),
      ),
      GoRoute(
        path: AppRoutes.projection,
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: ProjectionPage()),
      ),
      ShellRoute(
        builder: (_, __, child) => AdaptiveScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TransactionsPage()),
          ),
          GoRoute(
            path: AppRoutes.budgets,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: BudgetsPage()),
          ),
          GoRoute(
            path: AppRoutes.savings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SavingsPage()),
          ),
          GoRoute(
            path: AppRoutes.envelopes,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: EnvelopesPage()),
          ),
          GoRoute(
            path: AppRoutes.family,
            pageBuilder: (_, __) => const NoTransitionPage(child: FamilyPage()),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AccountsPage()),
          ),
          GoRoute(
            path: AppRoutes.recurring,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: RecurringTransactionsPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
