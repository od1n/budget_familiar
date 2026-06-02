import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/virtual_envelopes_table.dart';

part 'virtual_envelopes_dao.g.dart';

@DriftAccessor(tables: [VirtualEnvelopesTable])
class VirtualEnvelopesDao extends DatabaseAccessor<AppDatabase>
    with _$VirtualEnvelopesDaoMixin {
  VirtualEnvelopesDao(super.db);

  Stream<List<VirtualEnvelopesTableData>> watchActiveEnvelopes({
    required String groupId,
  }) =>
      (select(virtualEnvelopesTable)
            ..where((t) =>
                t.groupId.equals(groupId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> upsertEnvelope(VirtualEnvelopesTableCompanion entry) =>
      into(virtualEnvelopesTable).insertOnConflictUpdate(entry);

  Future<void> updateSpent({
    required String id,
    required double newSpent,
  }) =>
      (update(virtualEnvelopesTable)..where((t) => t.id.equals(id))).write(
        VirtualEnvelopesTableCompanion(
          spentAmount: Value(newSpent),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> archiveEnvelope(String id) =>
      (update(virtualEnvelopesTable)..where((t) => t.id.equals(id))).write(
        VirtualEnvelopesTableCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteEnvelope(String id) =>
      (delete(virtualEnvelopesTable)..where((t) => t.id.equals(id))).go();
}
