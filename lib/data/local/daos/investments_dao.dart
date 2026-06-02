import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/investments_table.dart';

part 'investments_dao.g.dart';

@DriftAccessor(tables: [InvestmentsTable])
class InvestmentsDao extends DatabaseAccessor<AppDatabase>
    with _$InvestmentsDaoMixin {
  InvestmentsDao(super.db);

  /// Stream de inversiones activas del grupo, ordenadas por fecha de creación.
  Stream<List<InvestmentsTableData>> watchActiveInvestments({
    required String groupId,
  }) =>
      (select(investmentsTable)
            ..where((t) => t.groupId.equals(groupId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Lista completa (activas + archivadas).
  Future<List<InvestmentsTableData>> getAllInvestments({
    required String groupId,
  }) =>
      (select(investmentsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<void> upsertInvestment(InvestmentsTableCompanion entry) =>
      into(investmentsTable).insertOnConflictUpdate(entry);

  Future<void> deleteInvestment(String id) =>
      (delete(investmentsTable)..where((t) => t.id.equals(id))).go();

  /// Actualiza solo el valor actual (para actualizaciones frecuentes de precio).
  Future<void> updateCurrentValue({
    required String id,
    required double newValue,
  }) =>
      (update(investmentsTable)..where((t) => t.id.equals(id))).write(
        InvestmentsTableCompanion(
          currentValue: Value(newValue),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Archiva en lugar de borrar (soft delete).
  Future<void> archiveInvestment(String id) =>
      (update(investmentsTable)..where((t) => t.id.equals(id))).write(
        InvestmentsTableCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
