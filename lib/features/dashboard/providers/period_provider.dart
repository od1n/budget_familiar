import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import 'dashboard_provider.dart' show MonthlyTrendPoint;

/// Modos de periodo que puede ver el usuario en el dashboard/reportes.
enum PeriodMode { month, yearToDate, fullYear, customRange }

/// Representa el periodo activo. Deriva un rango [start, end] concreto según
/// el modo, que las consultas del DAO usan de forma uniforme.
class Period {
  const Period({
    required this.mode,
    required this.anchor,
    this.rangeStart,
    this.rangeEnd,
  });

  final PeriodMode mode;

  /// Para `month`: primer día del mes. Para `yearToDate`/`fullYear`: cualquier
  /// fecha del año. Para `customRange`: se usa [rangeStart]/[rangeEnd].
  final DateTime anchor;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  static Period currentMonth() {
    final n = DateTime.now();
    return Period(mode: PeriodMode.month, anchor: DateTime(n.year, n.month));
  }

  DateTime get start => switch (mode) {
        PeriodMode.month => DateTime(anchor.year, anchor.month),
        PeriodMode.yearToDate => DateTime(anchor.year, 1, 1),
        PeriodMode.fullYear => DateTime(anchor.year, 1, 1),
        PeriodMode.customRange =>
          DateTime(rangeStart!.year, rangeStart!.month, rangeStart!.day),
      };

  DateTime get end => switch (mode) {
        // Día 0 del mes siguiente = último día del mes actual.
        PeriodMode.month => DateTime(anchor.year, anchor.month + 1, 0),
        PeriodMode.yearToDate => DateTime.now(),
        PeriodMode.fullYear => DateTime(anchor.year, 12, 31),
        PeriodMode.customRange =>
          DateTime(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day),
      };

  int get year => anchor.year;

  /// `true` cuando el modo es un mes y ese mes es el mes actual (para
  /// deshabilitar el botón "siguiente").
  bool get isCurrentMonth {
    final n = DateTime.now();
    return mode == PeriodMode.month &&
        anchor.year == n.year &&
        anchor.month == n.month;
  }
}

class SelectedPeriod extends Notifier<Period> {
  @override
  Period build() => Period.currentMonth();

  void setMonth(DateTime month) => state =
      Period(mode: PeriodMode.month, anchor: DateTime(month.year, month.month));

  void previousMonth() {
    final a = state.mode == PeriodMode.month ? state.anchor : DateTime.now();
    state = Period(
      mode: PeriodMode.month,
      anchor: DateTime(a.year, a.month - 1),
    );
  }

  void nextMonth() {
    final a = state.mode == PeriodMode.month ? state.anchor : DateTime.now();
    final n = DateTime.now();
    final next = DateTime(a.year, a.month + 1);
    if (next.isBefore(DateTime(n.year, n.month + 1))) {
      state = Period(mode: PeriodMode.month, anchor: next);
    }
  }

  void setYearToDate([int? year]) => state = Period(
        mode: PeriodMode.yearToDate,
        anchor: DateTime(year ?? DateTime.now().year),
      );

  void setFullYear([int? year]) => state = Period(
        mode: PeriodMode.fullYear,
        anchor: DateTime(year ?? DateTime.now().year),
      );

  void setCustomRange(DateTime start, DateTime end) => state = Period(
        mode: PeriodMode.customRange,
        anchor: start,
        rangeStart: start,
        rangeEnd: end,
      );
}

final selectedPeriodProvider =
    NotifierProvider<SelectedPeriod, Period>(SelectedPeriod.new);

/// Desglose de los 12 meses del año [year] (para el modo "año completo").
final fullYearBreakdownProvider = FutureProvider.family<
    List<MonthlyTrendPoint>,
    ({String groupId, int year})>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final points = <MonthlyTrendPoint>[];
  for (int m = 1; m <= 12; m++) {
    // No calcular meses futuros del año en curso.
    if (args.year == now.year && m > now.month) break;
    final start = DateTime(args.year, m, 1);
    final end = DateTime(args.year, m + 1, 0);
    final s = await db.transactionsDao
        .getSummaryForRange(groupId: args.groupId, start: start, end: end);
    points.add(
      MonthlyTrendPoint(
        month: start,
        income: s.totalIncome,
        expense: s.totalExpense,
      ),
    );
  }
  return points;
});
