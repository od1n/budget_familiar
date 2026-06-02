import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_transactions_table.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactionsTable])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  /// Stream de todas las recurrentes activas del grupo.
  Stream<List<RecurringTransactionsTableData>> watchActive(String groupId) =>
      (select(recurringTransactionsTable)
            ..where((r) => r.groupId.equals(groupId))
            ..where((r) => r.isActive.equals(true))
            ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
          .watch();

  /// Recurrentes vencidas (next_due_date ≤ hoy) y activas.
  Future<List<RecurringTransactionsTableData>> getOverdue(String groupId) {
    final now = DateTime.now();
    return (select(recurringTransactionsTable)
          ..where((r) => r.groupId.equals(groupId))
          ..where((r) => r.isActive.equals(true))
          ..where((r) => r.nextDueDate.isSmallerOrEqualValue(now)))
        .get();
  }

  Future<void> insert(RecurringTransactionsTableCompanion entry) =>
      into(recurringTransactionsTable).insert(entry);

  Future<void> update_(RecurringTransactionsTableCompanion entry) =>
      (update(recurringTransactionsTable)
            ..where((r) => r.id.equals(entry.id.value)))
          .write(entry);

  /// Actualiza solo la próxima fecha de vencimiento.
  Future<void> updateNextDue(String id, DateTime nextDue) =>
      (update(recurringTransactionsTable)..where((r) => r.id.equals(id)))
          .write(
        RecurringTransactionsTableCompanion(nextDueDate: Value(nextDue)),
      );

  /// Desactiva la recurrente sin eliminarla.
  Future<void> deactivate(String id) =>
      (update(recurringTransactionsTable)..where((r) => r.id.equals(id)))
          .write(
        const RecurringTransactionsTableCompanion(isActive: Value(false)),
      );

  Future<void> delete_(String id) =>
      (delete(recurringTransactionsTable)..where((r) => r.id.equals(id))).go();

  Future<void> upsert(RecurringTransactionsTableCompanion entry) =>
      into(recurringTransactionsTable).insertOnConflictUpdate(entry);
}
