import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/widget_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/transactions_dao.dart';
import 'period_provider.dart';

part 'dashboard_provider.g.dart';

// ── Modelo de tendencia ───────────────────────────────────────────────────────

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });
  final DateTime month;
  final double income;
  final double expense;
}

@riverpod
class ActiveMonth extends _$ActiveMonth {
  @override
  DateTime build() => DateTime.now();

  void previous() => state = DateTime(state.year, state.month - 1);
  void next() {
    final now = DateTime.now();
    final next = DateTime(state.year, state.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) state = next;
  }
}

@riverpod
Stream<MonthlySummary> monthlySummary(
  MonthlySummaryRef ref, {
  required String groupId,
}) {
  final db = ref.watch(appDatabaseProvider);
  final period = ref.watch(selectedPeriodProvider);
  final stream = db.transactionsDao.watchSummaryForRange(
    groupId: groupId,
    start: period.start,
    end: period.end,
  );
  // Actualizar el widget de Android cuando cambia el resumen mensual.
  return stream.map((summary) {
    WidgetService.instance.updateBalance(
      balance: summary.balance,
      income: summary.totalIncome,
      expense: summary.totalExpense,
    );
    return summary;
  });
}

@riverpod
Stream<Map<String, double>> expenseByCategory(
  ExpenseByCategoryRef ref, {
  required String groupId,
}) {
  final db = ref.watch(appDatabaseProvider);
  final period = ref.watch(selectedPeriodProvider);
  return db.transactionsDao.watchExpenseByCategoryForRange(
    groupId: groupId,
    start: period.start,
    end: period.end,
  );
}

@riverpod
Stream<List<TransactionsTableData>> recentTransactions(
  RecentTransactionsRef ref, {
  required String groupId,
}) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionsDao.watchRecent(groupId: groupId, limit: 5);
}

@riverpod
Future<List<MonthlyTrendPoint>> monthlyTrend(
  MonthlyTrendRef ref, {
  required String groupId,
}) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final points = <MonthlyTrendPoint>[];
  for (int i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i);
    final s = await db.transactionsDao.getMonthlySummary(
      groupId: groupId,
      year: m.year,
      month: m.month,
    );
    points.add(
      MonthlyTrendPoint(
        month: m,
        income: s.totalIncome,
        expense: s.totalExpense,
      ),
    );
  }
  return points;
}
