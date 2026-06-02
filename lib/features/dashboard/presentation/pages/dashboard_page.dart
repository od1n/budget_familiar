import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/daos/transactions_dao.dart';
import '../../../../router/app_router.dart';
import '../../../family/providers/family_provider.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../../accounts/providers/accounts_provider.dart';
import '../../../recurring/providers/recurring_transactions_provider.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dashboard_provider.dart';

// ── Helpers globales ──────────────────────────────────────────────────────────

String _catLabel(String id) => switch (id) {
      'sys_food' => 'Alimentación',
      'sys_transport' => 'Transporte',
      'sys_services' => 'Servicios',
      'sys_health' => 'Salud',
      'sys_education' => 'Educación',
      'sys_entertainment' => 'Entretenimiento',
      'sys_clothing' => 'Ropa',
      'sys_home' => 'Hogar',
      'sys_debt' => 'Deudas',
      _ => 'Otros',
    };

String _fmtMoney(double v) => NumberFormat('#,##0.00', 'es').format(v);

String _fmtAxis(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

// ── Página ────────────────────────────────────────────────────────────────────

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMonth = ref.watch(activeMonthProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final showAd = !isPremium && ref.read(adServiceProvider).isSupported;

    final s = S.of(context);
    return Scaffold(
      appBar: _DashboardAppBar(activeMonth: activeMonth),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const _RecurringAlertCard(),
          const _BalanceCard(),
          const SizedBox(height: AppSpacing.lg),
          const _AccountsSummarySection(),
          _SectionTitle(s.trendTitle),
          const SizedBox(height: AppSpacing.sm),
          const _TrendBarChart(),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(s.expenseDistTitle),
          const SizedBox(height: AppSpacing.sm),
          const _ExpensePieChart(),
          if (showAd) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: AdBannerWidget()),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(s.aiTitle),
          const SizedBox(height: AppSpacing.sm),
          const _AiRecommendationsCard(),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(s.recentTitle),
          const SizedBox(height: AppSpacing.sm),
          const _RecentTransactionsList(),
          const SizedBox(height: AppSpacing.x5l),
        ],
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _DashboardAppBar({required this.activeMonth});
  final DateTime activeMonth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = DateFormat('MMMM yyyy', 'es').format(activeMonth);
    final isCurrent = activeMonth.year == DateTime.now().year &&
        activeMonth.month == DateTime.now().month;

    return AppBar(
      title: Text(label[0].toUpperCase() + label.substring(1)),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(activeMonthProvider.notifier).previous(),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrent
              ? null
              : () => ref.read(activeMonthProvider.notifier).next(),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

// ── Tarjeta de balance ────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(activeGroupIdProvider);
    final async = ref.watch(monthlySummaryProvider(groupId: groupId));
    return async.when(
      loading: () => const _Skeleton(height: 140),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (s) => _BalanceCardContent(summary: s),
    );
  }
}

class _BalanceCardContent extends ConsumerWidget {
  const _BalanceCardContent({required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = summary.balance >= 0 ? AppColors.income : AppColors.expense;
    final rates = ref.watch(vesRatesProvider).valueOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).balanceOfMonth,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '\$ ${_fmtMoney(summary.balance)}',
              style: AppTypography.moneyDisplayLarge.copyWith(color: color),
            ),
            if (rates != null && rates.parallel > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Bs. ${_fmtMoney(summary.balance * rates.parallel)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Paralela Bs.${rates.parallel.toStringAsFixed(0)}/\$',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (summary.hasMixedCurrencies) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      S.of(context).mixedCurrencyWarning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: S.of(context).incomeLabel,
                    value: summary.totalIncome,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: S.of(context).expenseLabel,
                    value: summary.totalExpense,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    '\$ ${_fmtMoney(value)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Gráfica de barras: tendencia 6 meses ─────────────────────────────────────

class _TrendBarChart extends ConsumerWidget {
  const _TrendBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(activeGroupIdProvider);
    final async = ref.watch(monthlyTrendProvider(groupId: groupId));
    return async.when(
      loading: () => const _Skeleton(height: 220),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (points) {
        // Si todos los valores son cero no hay nada que mostrar
        final hasData = points.any((p) => p.income > 0 || p.expense > 0);
        if (!hasData) {
          return _EmptyState(
            icon: Icons.bar_chart_outlined,
            message: S.of(context).trendNoData,
          );
        }

        final maxY = points
                .expand((p) => [p.income, p.expense])
                .fold(0.0, (a, b) => b > a ? b : a) *
            1.2;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leyenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _LegendDot(color: AppColors.income, label: S.of(context).incomeLabel),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: AppColors.expense, label: S.of(context).expenseLabel),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY > 0 ? maxY : 100,
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: points.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.income,
                              color: AppColors.income,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: e.value.expense,
                              color: AppColors.expense,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) => Text(
                              _fmtAxis(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('MMM', 'es')
                                      .format(points[idx].month),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Gráfica donut: distribución de gastos ────────────────────────────────────

class _ExpensePieChart extends ConsumerWidget {
  const _ExpensePieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(activeGroupIdProvider);
    final async = ref.watch(expenseByCategoryProvider(groupId: groupId));
    return async.when(
      loading: () => const _Skeleton(height: 160),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (map) {
        if (map.isEmpty) {
          return _EmptyState(
            icon: Icons.pie_chart_outline,
            message: S.of(context).noExpensesMonth,
          );
        }
        final total = map.values.fold(0.0, (a, b) => a + b);
        final sorted = map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sections: top5.asMap().entries.map((e) {
                        final color = AppColors.chartPalette[
                            e.key % AppColors.chartPalette.length];
                        return PieChartSectionData(
                          value: e.value.value,
                          color: color,
                          radius: 42,
                          showTitle: false,
                        );
                      }).toList(),
                      centerSpaceRadius: 32,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Leyenda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: top5.asMap().entries.map((e) {
                      final color = AppColors
                          .chartPalette[e.key % AppColors.chartPalette.length];
                      final pct = total > 0
                          ? (e.value.value / total * 100).toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _catLabel(e.value.key),
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Resumen de cuentas ────────────────────────────────────────────────────────

class _AccountsSummarySection extends ConsumerWidget {
  const _AccountsSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();
        final db = ref.watch(appDatabaseProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).myAccounts,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.accounts),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(S.of(context).viewAll),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (ctx, i) => _AccountCard(
                  account: accounts[i],
                  db: db,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.db});

  final AccountsTableData account;
  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.colorHex);
    final icon = iconFromCode(account.iconCode);

    return FutureBuilder<double>(
      future: db.accountsDao.getBalance(account.id),
      builder: (context, snap) {
        final balance = snap.data ?? 0.0;
        final isPositive = balance >= 0;
        final balanceColor =
            isPositive ? AppColors.income : AppColors.expense;

        return Container(
          width: 150,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: balanceColor,
                    ),
                  ),
                  Text(
                    account.currencyCode,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Últimos movimientos ───────────────────────────────────────────────────────

class _RecentTransactionsList extends ConsumerWidget {
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(activeGroupIdProvider);
    final async = ref.watch(recentTransactionsProvider(groupId: groupId));
    return async.when(
      loading: () => Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Skeleton(height: AppSpacing.listItemHeight),
          ),
        ),
      ),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (txs) {
        if (txs.isEmpty) {
          return _EmptyState(
            icon: Icons.receipt_long_outlined,
            message: S.of(context).noRecentTransactions,
          );
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _TxTile(tx: txs[i]),
          ),
        );
      },
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final TransactionsTableData tx;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 18,
        ),
      ),
      title: Text(
        tx.description ?? (isIncome ? S.of(context).incomeTypeButton : S.of(context).expenseTypeButton),
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('d MMM', 'es').format(tx.date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'} ${tx.currencyCode} ${_fmtMoney(tx.amount)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Alerta de recurrentes vencidos ────────────────────────────────────────────

class _RecurringAlertCard extends ConsumerWidget {
  const _RecurringAlertCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(recurringListProvider);

    return asyncList.when(
      data: (templates) {
        final now = DateTime.now();
        final overdue = templates
            .where((t) => t.isActive && t.nextDueDate.isBefore(now))
            .length;
        if (overdue == 0) return const SizedBox.shrink();

        return Card(
          color: AppColors.warning.withValues(alpha: 0.12),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    S.of(context).recurringAlertCount(overdue),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.recurring),
                  child: Text(S.of(context).viewButton),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3l),
          child: Column(
            children: [
              Icon(icon, size: 40, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.expenseLight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.expense),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      );
}

// ── Card de recomendaciones IA ─────────────────────────────────────────────────

class _AiRecommendationsCard extends ConsumerStatefulWidget {
  const _AiRecommendationsCard();

  @override
  ConsumerState<_AiRecommendationsCard> createState() =>
      _AiRecommendationsCardState();
}

class _AiRecommendationsCardState
    extends ConsumerState<_AiRecommendationsCard> {
  AiInsight? _insight;
  String? _error;
  bool _loading = false;

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    final groupId = ref.read(activeGroupIdProvider);
    final result = await InsightsService.instance.generateInsight(
      groupId: groupId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _insight = result.insight;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canUseAi = ref.watch(hasAiAccessProvider);

    // Gate: solo Premium/Beta
    if (!canUseAi) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  S.of(context).aiPremiumOnly,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: Text(S.of(context).viewPlans),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(S.of(context).aiAnalyzing,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // Estado vacío — primer acceso
    if (_insight == null && _error == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                S.of(context).aiCompleteTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Compara 3 meses de historial, analiza metas,\n'
                'inversiones y contexto económico venezolano.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.auto_awesome),
                label: Text(S.of(context).generateAnalysis),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 44)),
              ),
            ],
          ),
        ),
      );
    }

    // Error
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: AppColors.expense),
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _load, child: Text(S.of(context).retryButton)),
            ],
          ),
        ),
      );
    }

    final ins = _insight!;
    final scoreColor = ins.healthScore == null
        ? AppColors.textDisabled
        : ins.healthScore! >= 70
            ? AppColors.income
            : ins.healthScore! >= 40
                ? AppColors.warning
                : AppColors.expense;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con health score
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(S.of(context).aiTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (ins.healthScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded,
                            size: 12, color: scoreColor),
                        const SizedBox(width: 4),
                        Text(
                          '${ins.healthScore}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _load,
                  tooltip: ins.fromCache ? 'Actualizar (en caché)' : 'Actualizar',
                ),
              ],
            ),
          ),

          // Contexto macro (si existe)
          if (ins.macroContext != null && ins.macroContext!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ins.macroContext!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],

          const Divider(height: AppSpacing.lg),

          // Recomendaciones
          ...ins.recommendations.map(
            (r) => _InsightRecommendationTile(r),
          ),

          // Pie con metadata
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Text(
              ins.fromCache ? S.of(context).aiCachedFooter : S.of(context).aiGeneratedNow,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textDisabled),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRecommendationTile extends StatelessWidget {
  const _InsightRecommendationTile(this.rec);
  final AiInsightRecommendation rec;

  Color get _priorityColor => switch (rec.priority) {
        'high'   => AppColors.expense,
        'medium' => AppColors.warning,
        _        => AppColors.textDisabled,
      };

  IconData get _typeIcon => switch (rec.type) {
        'spending_alert'   => Icons.trending_down,
        'savings_tip'      => Icons.savings_outlined,
        'investment_advice'=> Icons.trending_up,
        'macro_context'    => Icons.currency_exchange,
        _                  => Icons.lightbulb_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _priorityColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon, size: 18, color: _priorityColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(rec.message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (rec.action != null && rec.action!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(rec.action!,
                      style: TextStyle(
                          fontSize: 11,
                          color: _priorityColor,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
