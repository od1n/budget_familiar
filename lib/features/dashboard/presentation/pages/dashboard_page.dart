import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/display_prefs_provider.dart';
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
import '../../../agenda/presentation/pages/agenda_page.dart';
import '../../../projections/presentation/pages/projection_page.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/period_provider.dart';

// ── Helpers globales ──────────────────────────────────────────────────────────

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
    final period = ref.watch(selectedPeriodProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final showAd = !isPremium && ref.read(adServiceProvider).isSupported;

    final s = S.of(context);
    return Scaffold(
      appBar: const _DashboardAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const _RecurringAlertCard(),
          const _BalanceCard(),
          if (period.mode == PeriodMode.fullYear) ...[
            const SizedBox(height: AppSpacing.lg),
            const _MonthlyBreakdownSection(),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _AccountsSummarySection(),
          const SizedBox(height: AppSpacing.lg),
          const UpcomingPaymentsCard(),
          const SizedBox(height: AppSpacing.lg),
          const ProjectionCard(),
          const SizedBox(height: AppSpacing.lg),
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
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _label(BuildContext context, Period p) {
    switch (p.mode) {
      case PeriodMode.month:
        final l = DateFormat('MMMM yyyy', 'es').format(p.anchor);
        return l[0].toUpperCase() + l.substring(1);
      case PeriodMode.yearToDate:
        return '${S.of(context).periodYearToDate} ${p.year}';
      case PeriodMode.fullYear:
        return '${p.year}';
      case PeriodMode.customRange:
        final fmt = DateFormat('d MMM', 'es');
        final fmtY = DateFormat('d MMM yyyy', 'es');
        return '${fmt.format(p.start)} — ${fmtY.format(p.end)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final isMonth = period.mode == PeriodMode.month;

    return AppBar(
      title: InkWell(
        onTap: () => _showPeriodMenu(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _label(context, period),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, size: 22),
            ],
          ),
        ),
      ),
      actions: [
        if (isMonth) ...[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(selectedPeriodProvider.notifier).previousMonth(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: period.isCurrentMonth
                ? null
                : () => ref.read(selectedPeriodProvider.notifier).nextMonth(),
          ),
        ] else
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showPeriodMenu(context, ref),
          ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Future<void> _showPeriodMenu(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final notifier = ref.read(selectedPeriodProvider.notifier);
    final current = ref.read(selectedPeriodProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    s.periodSelectTitle,
                    style: Theme.of(sheetCtx).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            _periodTile(sheetCtx, Icons.calendar_view_month,
                s.periodCurrentMonth, current.mode == PeriodMode.month, () {
              notifier.setMonth(DateTime.now());
              Navigator.pop(sheetCtx);
            }),
            _periodTile(sheetCtx, Icons.event_available, s.periodYearToDate,
                current.mode == PeriodMode.yearToDate, () {
              notifier.setYearToDate();
              Navigator.pop(sheetCtx);
            }),
            _periodTile(sheetCtx, Icons.calendar_month, s.periodFullYear,
                current.mode == PeriodMode.fullYear, () {
              notifier.setFullYear();
              Navigator.pop(sheetCtx);
            }),
            _periodTile(sheetCtx, Icons.date_range, s.periodCustomRange,
                current.mode == PeriodMode.customRange, () async {
              Navigator.pop(sheetCtx);
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: now,
                initialDateRange: current.mode == PeriodMode.customRange
                    ? DateTimeRange(start: current.start, end: current.end)
                    : null,
                locale: const Locale('es'),
              );
              if (picked != null) {
                notifier.setCustomRange(picked.start, picked.end);
              }
            }),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _periodTile(BuildContext context, IconData icon, String label,
          bool selected, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon,
            color: selected ? AppColors.primary : AppColors.textSecondary),
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check, color: AppColors.primary, size: 20)
            : null,
        onTap: onTap,
      );
}

// ── Desglose por mes (modo "año completo") ────────────────────────────────────

class _MonthlyBreakdownSection extends ConsumerWidget {
  const _MonthlyBreakdownSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final groupId = ref.watch(activeGroupIdProvider);
    final period = ref.watch(selectedPeriodProvider);
    final async = ref.watch(
      fullYearBreakdownProvider((groupId: groupId, year: period.year)),
    );

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (points) {
        if (points.isEmpty) return const SizedBox.shrink();
        final fmt = DateFormat('MMM', 'es');
        double yInc = 0, yExp = 0;
        for (final p in points) {
          yInc += p.income;
          yExp += p.expense;
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.monthlyBreakdownTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _breakdownHeader(context, s),
                const Divider(height: 12),
                ...points.map((p) {
                  final m = fmt.format(p.month);
                  return _breakdownRow(
                    context,
                    m[0].toUpperCase() + m.substring(1),
                    p.income,
                    p.expense,
                    p.income - p.expense,
                    bold: false,
                  );
                }),
                const Divider(height: 12),
                _breakdownRow(
                  context,
                  '${period.year}',
                  yInc,
                  yExp,
                  yInc - yExp,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _breakdownHeader(BuildContext context, S s) {
    const st = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary);
    return Row(
      children: [
        const Expanded(flex: 2, child: SizedBox()),
        Expanded(
            flex: 3,
            child: Text(s.incomeLabel, style: st, textAlign: TextAlign.right)),
        Expanded(
            flex: 3,
            child: Text(s.expenseLabel, style: st, textAlign: TextAlign.right)),
        Expanded(
            flex: 3,
            child:
                Text(s.balanceShort, style: st, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _breakdownRow(BuildContext context, String label, double inc,
      double exp, double bal, {required bool bold}) {
    final w = bold ? FontWeight.w700 : FontWeight.w400;
    final base = TextStyle(fontSize: 12, fontWeight: w);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: base.copyWith(color: AppColors.textSecondary))),
          Expanded(
              flex: 3,
              child: Text('\$ ${_fmtMoney(inc)}',
                  style: base.copyWith(color: AppColors.income),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text('\$ ${_fmtMoney(exp)}',
                  style: base.copyWith(color: AppColors.expense),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text('\$ ${_fmtMoney(bal)}',
                  style: base.copyWith(
                      color: bal >= 0
                          ? AppColors.textPrimary
                          : AppColors.expense),
                  textAlign: TextAlign.right)),
        ],
      ),
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
    final prefs = ref.watch(displayPrefsProvider);
    final isBcv = prefs.rate == 'bcv';
    final autoRate = isBcv ? (rates?.bcv ?? 0) : (rates?.parallel ?? 0);
    final manualVes = prefs.manualVesRate; // Bs. por 1 USD; 0 = automática
    final rateVal = manualVes > 0 ? manualVes : autoRate;
    final eurUsd = rates?.eurUsd ?? 0; // USD por 1 EUR (forex real)
    final usdMxn = rates?.usdMxn ?? 0; // MXN por 1 USD
    final arsBlue = rates?.usdArsBlue ?? 0;
    final arsOf = rates?.usdArsOficial ?? 0;
    final arsRate = arsBlue > 0 ? arsBlue : arsOf; // ARS por 1 USD (blue preferido)
    final hasRate = rateVal > 0;
    final hasEur = eurUsd > 0;
    final hasMxn = usdMxn > 0;
    final hasArs = arsRate > 0;
    final hasConv = hasRate || hasEur || hasMxn || hasArs;

    // Moneda de visualización efectiva (cae a USD si falta la tasa necesaria).
    var cur = prefs.currency;
    if (cur == 'VES' && !hasRate) cur = 'USD';
    if (cur == 'EUR' && !hasEur) cur = 'USD';
    if (cur == 'MXN' && !hasMxn) cur = 'USD';
    if (cur == 'ARS' && !hasArs) cur = 'USD';

    String fmtIn(String c, double usd) {
      switch (c) {
        case 'VES':
          return 'Bs. ${_fmtMoney(usd * rateVal)}';
        case 'EUR':
          return '€ ${_fmtMoney(eurUsd > 0 ? usd / eurUsd : usd)}';
        case 'MXN':
          return 'MX\$ ${_fmtMoney(usdMxn > 0 ? usd * usdMxn : usd)}';
        case 'ARS':
          return 'AR\$ ${_fmtMoney(arsRate > 0 ? usd * arsRate : usd)}';
        default:
          return '\$ ${_fmtMoney(usd)}';
      }
    }

    // Moneda de la línea secundaria (referencia).
    String? secondaryCur;
    if (cur == 'USD') {
      secondaryCur = hasRate ? 'VES' : (hasEur ? 'EUR' : null);
    } else {
      secondaryCur = 'USD';
    }

    final currencyOptions = <String>[
      'USD',
      if (hasRate) 'VES',
      if (hasEur) 'EUR',
      if (hasMxn) 'MXN',
      if (hasArs) 'ARS',
    ];
    final rateLabel = manualVes > 0 ? 'Manual' : (isBcv ? 'BCV' : 'Paralela');
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
              fmtIn(cur, summary.balance),
              style: AppTypography.moneyDisplayLarge.copyWith(color: color),
            ),
            if (hasConv) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (secondaryCur != null)
                    Text(
                      fmtIn(secondaryCur!, summary.balance),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (hasRate) ...[
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
                        '$rateLabel Bs.${rateVal.toStringAsFixed(0)}/\$',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MiniToggle(
                      options: currencyOptions,
                      selected: cur,
                      onChanged: (v) => ref
                          .read(displayPrefsProvider.notifier)
                          .setCurrency(v),
                    ),
                    if (hasRate) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _MiniToggle(
                        options: const ['parallel', 'bcv'],
                        labels: const ['Paralela', 'BCV'],
                        selected: prefs.rate,
                        onChanged: (v) =>
                            ref.read(displayPrefsProvider.notifier).setRate(v),
                      ),
                    ],
                  ],
                ),
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
                    display: fmtIn(cur, summary.totalIncome),
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: S.of(context).expenseLabel,
                    display: fmtIn(cur, summary.totalExpense),
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
    required this.display,
    required this.color,
    required this.icon,
  });
  final String label;
  final String display;
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
                    display,
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

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labels,
  });
  final List<String> options;
  final List<String>? labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final opt = options[i];
          final lbl = labels != null ? labels![i] : opt;
          final active = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lbl,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
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
                                categoryDisplayName(context, e.value.key, S.of(context).sysCatOther),
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
              Text(
                S.of(context).aiInsightsDesc,
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
