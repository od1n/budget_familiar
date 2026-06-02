import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/savings_goals_table.dart';

part 'savings_goals_dao.g.dart';

@DriftAccessor(tables: [SavingsGoalsTable])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  Stream<List<SavingsGoalsTableData>> watchGoals({required String groupId}) =>
      (select(savingsGoalsTable)
            ..where((g) => g.groupId.equals(groupId))
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .watch();

  Future<void> upsertGoal(SavingsGoalsTableCompanion entry) =>
      into(savingsGoalsTable).insertOnConflictUpdate(entry);

  Future<void> deleteGoal(String id) =>
      (delete(savingsGoalsTable)..where((g) => g.id.equals(id))).go();

  Future<void> updateCurrentAmount({
    required String id,
    required double newAmount,
  }) =>
      (update(savingsGoalsTable)..where((g) => g.id.equals(id))).write(
        SavingsGoalsTableCompanion(
          currentAmount: Value(newAmount),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Activa/desactiva ajuste por inflación para una meta.
  /// [monthlyRate] = null desactiva el ajuste; un valor activa con esa tasa.
  Future<void> updateInflationRate({
    required String id,
    required double? monthlyRate,
  }) =>
      (update(savingsGoalsTable)..where((g) => g.id.equals(id))).write(
        SavingsGoalsTableCompanion(
          inflationRateMonthly: Value(monthlyRate),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    required String currencyCode,
    DateTime? targetDate,
    String? iconCode,
  }) =>
      (update(savingsGoalsTable)..where((g) => g.id.equals(id))).write(
        SavingsGoalsTableCompanion(
          name: Value(name),
          targetAmount: Value(targetAmount),
          currencyCode: Value(currencyCode),
          targetDate: Value(targetDate),
          iconCode: iconCode != null ? Value(iconCode) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
