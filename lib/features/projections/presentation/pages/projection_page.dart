import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../router/app_router.dart';
import '../../../dashboard/providers/display_prefs_provider.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/projection_provider.dart';
import '../../services/projection_service.dart';

// ── Conversión y formato en la moneda de visualización ────────────────────────

/// Parámetros de conversión desde USD hacia la moneda que el usuario eligió
/// mostrar. Se calculan una vez por construcción a partir de preferencias+tasas.
class _DisplayMoney {
  const _DisplayMoney({
    required this.currency,
    required this.vesRate,
    required this.eurUsd,
    required this.usdMxn,
    required this.arsRate,
  });

  final String currency; // moneda efectiva ya validada (cae a USD si falta tasa)
  final double vesRate; // Bs. por 1 USD
  final double eurUsd; // USD por 1 EUR
  final double usdMxn; // MXN por 1 USD
  final double arsRate; // ARS por 1 USD

  String format(double usd) {
    final n = NumberFormat('#,##0.00', 'es');
    switch (currency) {
      case 'VES':
        return 'Bs. ${n.format(usd * vesRate)}';
      case 'EUR':
        return '€ ${n.format(eurUsd > 0 ? usd / eurUsd : usd)}';
      case 'MXN':
        return 'MX\$ ${n.format(usdMxn > 0 ? usd * usdMxn : usd)}';
      case 'ARS':
        return 'AR\$ ${n.format(usd * arsRate)}';
      default:
        return '\$ ${n.format(usd)}';
    }
  }

  /// Valor numérico en la moneda de visualización (para la gráfica).
  double value(double usd) {
    switch (currency) {
      case 'VES':
        return usd * vesRate;
      case 'EUR':
        return eurUsd > 0 ? usd / eurUsd : usd;
      case 'MXN':
        return usdMxn > 0 ? usd * usdMxn : usd;
      case 'ARS':
        return usd * arsRate;
      default:
        return usd;
    }
  }
}

_DisplayMoney _resolveDisplayMoney(WidgetRef ref) {
  final prefs = ref.watch(displayPrefsProvider);
  final rates = ref.watch(vesRatesProvider).valueOrNull;

  final isBcv = prefs.rate == 'bcv';
  final autoVes = isBcv ? (rates?.bcv ?? 0) : (rates?.parallel ?? 0);
  final manualVes = prefs.manualVesRate;
  final vesRate = manualVes > 0 ? manualVes : autoVes;
  final eurUsd = rates?.eurUsd ?? 0;
  final usdMxn = rates?.usdMxn ?? 0;
  final arsBlue = rates?.usdArsBlue ?? 0;
  final arsOf = rates?.usdArsOficial ?? 0;
  final arsRate = arsBlue > 0 ? arsBlue : arsOf;

  var cur = prefs.currency;
  if (cur == 'VES' && vesRate <= 0) cur = 'USD';
  if (cur == 'EUR' && eurUsd <= 0) cur = 'USD';
  if (cur == 'MXN' && usdMxn <= 0) cur = 'USD';
  if (cur == 'ARS' && arsRate <= 0) cur = 'USD';

  return _DisplayMoney(
    currency: cur,
    vesRate: vesRate,
    eurUsd: eurUsd,
    usdMxn: usdMxn,
    arsRate: arsRate,
  );
}

String _fmtAxis(double v) {
  final a = v.abs();
  if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (a >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

String _monthLabel(DateTime d) {
  final l = DateFormat('MMM', 'es').format(d);
  return l[0].toUpperCase() + l.substring(1);
}

String _monthLabelLong(DateTime d) {
  final l = DateFormat('MMMM yyyy', 'es').format(d);
  return l[0].toUpperCase() + l.substring(1);
}

// ── Pantalla completa ─────────────────────────────────────────────────────────

class ProjectionPage extends ConsumerWidget {
  const ProjectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Funcionalidad Premium (misma puerta que el análisis con IA).
    if (!ref.watch(hasAiAccessProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyección de saldo')),
        body: const _PremiumLock(),
      );
    }

    final async = ref.watch(projectionProvider);
    final horizon = ref.watch(projectionHorizonProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Proyección de saldo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2l),
            child: Text('No se pudo calcular la proyección.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (result) {
          final money = _resolveDisplayMoney(ref);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _HorizonSelector(selected: horizon),
              const SizedBox(height: AppSpacing.lg),
              _SummaryCard(result: result, money: money),
              const SizedBox(height: AppSpacing.lg),
              if (result.points.isEmpty)
                const _EmptyProjection()
              else ...[
                _ProjectionChart(result: result, money: money),
                const SizedBox(height: AppSpacing.lg),
                _MonthlyTable(result: result, money: money),
              ],
              const SizedBox(height: AppSpacing.lg),
              _MethodNote(result: result, money: money),
            ],
          );
        },
      ),
    );
  }
}

// ── Selector de horizonte ─────────────────────────────────────────────────────

class _HorizonSelector extends ConsumerWidget {
  const _HorizonSelector({required this.selected});
  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 3, label: Text('3 meses')),
        ButtonSegment(value: 6, label: Text('6 meses')),
        ButtonSegment(value: 12, label: Text('12 meses')),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(projectionHorizonProvider.notifier).state = s.first,
    );
  }
}

// ── Tarjeta de resumen ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.money});
  final ProjectionResult result;
  final _DisplayMoney money;

  @override
  Widget build(BuildContext context) {
    final start = result.startingBalanceUsd;
    final end = result.endingBalanceUsd;
    final delta = end - start;
    final up = delta >= 0;
    final deltaColor = up ? AppColors.income : AppColors.expense;
    final negIdx = result.firstNegativeMonthIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    label: 'Saldo actual',
                    value: money.format(start),
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.arrow_forward,
                    size: 18, color: AppColors.textDisabled),
                Expanded(
                  child: _StatBlock(
                    label: result.points.isEmpty
                        ? 'Proyección'
                        : 'En ${result.points.length} meses',
                    value: money.format(end),
                    color: end >= 0 ? AppColors.textPrimary : AppColors.expense,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(up ? Icons.trending_up : Icons.trending_down,
                    size: 16, color: deltaColor),
                const SizedBox(width: 6),
                Text(
                  '${up ? '+' : ''}${money.format(delta)} en el período',
                  style: TextStyle(
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (negIdx != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.expense),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Con este ritmo, tu saldo quedaría en negativo en '
                        '${_monthLabelLong(result.points[negIdx].month)}.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── Gráfica de línea ──────────────────────────────────────────────────────────

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.result, required this.money});
  final ProjectionResult result;
  final _DisplayMoney money;

  @override
  Widget build(BuildContext context) {
    // Punto 0 = hoy (saldo actual); puntos 1..N = meses proyectados.
    final spots = <FlSpot>[
      FlSpot(0, money.value(result.startingBalanceUsd)),
      for (var i = 0; i < result.points.length; i++)
        FlSpot((i + 1).toDouble(), money.value(result.points[i].balanceUsd)),
    ];

    final values = spots.map((s) => s.y).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    // Margen y asegurar que el cero sea visible cuando hay negativos.
    if (minY > 0) minY = 0;
    if (maxY < 0) maxY = 0;
    final span = (maxY - minY).abs();
    final pad = span == 0 ? 100.0 : span * 0.15;
    minY -= pad;
    maxY += pad;

    final n = result.points.length;
    // Muestra ~6 etiquetas en el eje inferior como máximo.
    final labelStep = (n / 6).ceil().clamp(1, 12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: n.toDouble(),
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItems: (spots) => spots.map((s) {
                    final label = s.x == 0
                        ? 'Hoy'
                        : _monthLabel(result.points[s.x.toInt() - 1].month);
                    return LineTooltipItem(
                      '$label\n${money.format(_toUsdForTooltip(s.x))}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: v.abs() < 0.01
                      ? AppColors.textSecondary
                      : AppColors.border,
                  strokeWidth: v.abs() < 0.01 ? 1.2 : 1,
                  dashArray: v.abs() < 0.01 ? null : [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.max || v == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(_fmtAxis(v),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (v != idx.toDouble()) return const SizedBox.shrink();
                      if (idx == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Hoy',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        );
                      }
                      final pi = idx - 1;
                      if (pi < 0 || pi >= n) return const SizedBox.shrink();
                      if (pi % labelStep != 0 && idx != n) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_monthLabel(result.points[pi].month),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: n <= 12,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: spot.y >= 0 ? AppColors.primary : AppColors.expense,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // La gráfica trabaja en la moneda de visualización, pero el tooltip vuelve a
  // formatear desde USD para mantener consistencia con las tarjetas.
  double _toUsdForTooltip(double x) {
    if (x == 0) return result.startingBalanceUsd;
    final i = x.toInt() - 1;
    if (i < 0 || i >= result.points.length) return 0;
    return result.points[i].balanceUsd;
  }
}

// ── Tabla mensual ─────────────────────────────────────────────────────────────

class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({required this.result, required this.money});
  final ProjectionResult result;
  final _DisplayMoney money;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalle mes a mes',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: const [
                Expanded(flex: 3, child: _Th('Mes')),
                Expanded(flex: 3, child: _Th('Ingreso', end: true)),
                Expanded(flex: 3, child: _Th('Gasto', end: true)),
                Expanded(flex: 4, child: _Th('Saldo', end: true)),
              ],
            ),
            const Divider(height: 12),
            ...result.points.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(_monthLabel(p.month),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(money.format(p.incomeUsd),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.income)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(money.format(p.expenseUsd),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.expense)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(money.format(p.balanceUsd),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.balanceUsd >= 0
                                  ? AppColors.textPrimary
                                  : AppColors.expense)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text, {this.end = false});
  final String text;
  final bool end;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: end ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
      );
}

// ── Nota de método ────────────────────────────────────────────────────────────

class _MethodNote extends StatelessWidget {
  const _MethodNote({required this.result, required this.money});
  final ProjectionResult result;
  final _DisplayMoney money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Cómo se calcula',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Parte de tu saldo actual (neto acumulado de tus movimientos). '
            'Cada mes suma los ingresos y gastos programados de la agenda y '
            'resta un colchón de gasto variable de '
            '${money.format(result.variableMonthlyExpenseUsd)} al mes, estimado '
            'con tu gasto de los últimos 3 meses por encima de lo ya '
            'programado. Es una estimación, no una garantía.',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          if (result.hasMissingRate) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nota: alguna plantilla usa una moneda cuya tasa no está '
              'disponible ahora; esos montos no se incluyeron. Actualiza las '
              'tasas y vuelve a entrar.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  height: 1.4,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyProjection extends StatelessWidget {
  const _EmptyProjection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          children: [
            const Icon(Icons.show_chart,
                size: 44, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no hay datos suficientes para proyectar.\n'
              'Agrega transacciones recurrentes (agenda) para ver tu saldo '
              'futuro.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta compacta para el panel ────────────────────────────────────────────

/// Acceso rápido a la proyección desde el panel: muestra el saldo proyectado al
/// final del horizonte y la variación. Se oculta si no hay proyección.
class ProjectionCard extends ConsumerWidget {
  const ProjectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Funcionalidad Premium: a los usuarios sin acceso se les muestra un acceso
    // a los planes en vez de la proyección.
    if (!ref.watch(hasAiAccessProvider)) {
      return const _ProjectionUpsellCard();
    }
    final async = ref.watch(projectionProvider);
    final result = async.valueOrNull;
    if (result == null || result.points.isEmpty) {
      return const SizedBox.shrink();
    }
    final money = _resolveDisplayMoney(ref);
    final delta = result.endingBalanceUsd - result.startingBalanceUsd;
    final up = delta >= 0;
    final deltaColor = up ? AppColors.income : AppColors.expense;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.push(AppRoutes.projection),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proyección a ${result.points.length} meses',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(money.format(result.endingBalanceUsd),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12, color: deltaColor),
                        Text('${up ? '+' : ''}${money.format(delta)}',
                            style: TextStyle(fontSize: 12, color: deltaColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Acceso Premium ────────────────────────────────────────────────────────────

/// Cuerpo de la pantalla completa para usuarios sin acceso Premium.
class _PremiumLock extends StatelessWidget {
  const _PremiumLock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Proyección Premium',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'La proyección de saldo está disponible en el plan Premium, '
              'junto con el análisis con inteligencia artificial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.paywall),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 44)),
              child: const Text('Ver planes'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta compacta del panel para usuarios sin acceso Premium: invita a ver
/// los planes en lugar de mostrar la proyección.
class _ProjectionUpsellCard extends StatelessWidget {
  const _ProjectionUpsellCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.push(AppRoutes.paywall),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proyección de saldo',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    const Text('Disponible en Premium',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.workspace_premium,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
