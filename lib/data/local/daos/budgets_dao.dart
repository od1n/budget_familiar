import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [BudgetsTable])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  /// Stream del mapa categoryId → monthlyLimit para un grupo.
  Stream<Map<String, double>> watchBudgetMap({required String groupId}) =>
      (select(budgetsTable)..where((b) => b.groupId.equals(groupId)))
          .watch()
          .map((rows) => {for (final r in rows) r.categoryId: r.monthlyLimit});

  Future<void> upsertBudget(BudgetsTableCompanion entry) =>
      into(budgetsTable).insertOnConflictUpdate(entry);

  Future<void> deleteBudget(String id) =>
      (delete(budgetsTable)..where((b) => b.id.equals(id))).go();

  /// Lee el límite mensual de una categoría (one-shot, sin stream).
  Future<double?> getLimitForCategory({
    required String groupId,
    required String categoryId,
  }) async {
    final row = await getForCategory(groupId: groupId, categoryId: categoryId);
    return row?.monthlyLimit;
  }

  /// Devuelve la fila completa para una categoría+grupo, o null si no existe.
  Future<BudgetsTableData?> getForCategory({
    required String groupId,
    required String categoryId,
  }) async {
    final rows = await (select(budgetsTable)
          ..where(
            (b) => b.groupId.equals(groupId) & b.categoryId.equals(categoryId),
          )
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Elimina el límite de una categoría específica para un grupo.
  Future<void> deleteByCategoryAndGroup({
    required String groupId,
    required String categoryId,
  }) =>
      (delete(budgetsTable)
            ..where(
              (b) =>
                  b.groupId.equals(groupId) & b.categoryId.equals(categoryId),
            ))
          .go();
}
