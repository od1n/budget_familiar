import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../features/budgets/providers/budget_alert_provider.dart';
import '../../../features/transactions/presentation/widgets/transaction_form.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';

class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha alertas de presupuesto y las muestra como SnackBar.
    // Cubre todas las plataformas; en móvil complementa la notificación del SO.
    ref.listen(budgetAlertProvider, (_, alert) {
      if (alert == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(alert.message),
          backgroundColor: alert.isOver ? AppColors.expense : AppColors.warning,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: S.of(context).okButton,
            textColor: Colors.white,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              ref.read(budgetAlertProvider.notifier).state = null;
            },
          ),
        ),
      );
    });

    final width = MediaQuery.sizeOf(context).width;
    return switch (width) {
      >= 1200 => _DesktopLayout(child: child),
      >= 800 => _TabletLayout(child: child),
      _ => _MobileLayout(child: child),
    };
  }
}

class _NavDest {
  const _NavDest({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String route;
  final Icon icon;
  final Icon activeIcon;
  final String label;
}

List<_NavDest> _destinations(BuildContext context) {
  final l = S.of(context);
  return [
    _NavDest(
      route: AppRoutes.dashboard,
      icon: const Icon(Icons.home_outlined),
      activeIcon: const Icon(Icons.home),
      label: l.navHome,
    ),
    _NavDest(
      route: AppRoutes.transactions,
      icon: const Icon(Icons.swap_horiz_outlined),
      activeIcon: const Icon(Icons.swap_horiz),
      label: l.navTransactions,
    ),
    _NavDest(
      route: AppRoutes.budgets,
      icon: const Icon(Icons.pie_chart_outline),
      activeIcon: const Icon(Icons.pie_chart),
      label: l.navBudgets,
    ),
    _NavDest(
      route: AppRoutes.savings,
      icon: const Icon(Icons.savings_outlined),
      activeIcon: const Icon(Icons.savings),
      label: l.navGoals,
    ),
    _NavDest(
      route: AppRoutes.accounts,
      icon: const Icon(Icons.account_balance_wallet_outlined),
      activeIcon: const Icon(Icons.account_balance_wallet),
      label: l.navAccounts,
    ),
    _NavDest(
      route: AppRoutes.envelopes,
      icon: const Icon(Icons.wallet_outlined),
      activeIcon: const Icon(Icons.wallet),
      label: l.navEnvelopes,
    ),
    _NavDest(
      route: AppRoutes.family,
      icon: const Icon(Icons.group_outlined),
      activeIcon: const Icon(Icons.group),
      label: l.navFamily,
    ),
    _NavDest(
      route: AppRoutes.settings,
      icon: const Icon(Icons.settings_outlined),
      activeIcon: const Icon(Icons.settings),
      label: l.navSettings,
    ),
  ];
}

int _selectedIndex(BuildContext context, List<_NavDest> dests) {
  final location = GoRouterState.of(context).matchedLocation;
  final idx = dests.indexWhere((d) => location.startsWith(d.route));
  return idx < 0 ? 0 : idx;
}

void _openQuickAdd(BuildContext context) =>
    openTransactionForm(context);

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dests = _destinations(context);
    final idx = _selectedIndex(context, dests);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickAdd(context),
        tooltip: S.of(context).navRegister,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(dests[i].route),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: dests
            .map(
              (d) => NavigationDestination(
                icon: d.icon,
                selectedIcon: d.activeIcon,
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Tablet ────────────────────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dests = _destinations(context);
    final idx = _selectedIndex(context, dests);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(dests[i].route),
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: FloatingActionButton.small(
                    onPressed: () => _openQuickAdd(context),
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
            destinations: dests
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.activeIcon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dests = _destinations(context);
    final idx = _selectedIndex(context, dests);
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: _DesktopSidebar(
              selectedIndex: idx,
              destinations: dests,
              onTap: (i) => context.go(dests[i].route),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.destinations,
    required this.onTap,
  });
  final int selectedIndex;
  final List<_NavDest> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.x3l,
              AppSpacing.lg,
              AppSpacing.x2l,
            ),
            child: Text(
              'Budget\nFamiliar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
          ),
          ...List.generate(destinations.length, (i) {
            final dest = destinations[i];
            final isSelected = i == selectedIndex;
            return InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      child: isSelected ? dest.activeIcon : dest.icon,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      dest.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton.icon(
              onPressed: () => _openQuickAdd(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(S.of(context).navRegister),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
