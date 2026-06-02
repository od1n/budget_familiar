import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/family_groups_table.dart';
import '../tables/group_members_table.dart';

part 'family_groups_dao.g.dart';

@DriftAccessor(tables: [FamilyGroupsTable, GroupMembersTable])
class FamilyGroupsDao extends DatabaseAccessor<AppDatabase>
    with _$FamilyGroupsDaoMixin {
  FamilyGroupsDao(super.db);

  // ── Grupos ────────────────────────────────────────────────────────────────

  /// Inserta o reemplaza el grupo en caché local.
  Future<void> upsertGroup(FamilyGroupsTableCompanion entry) =>
      into(familyGroupsTable).insertOnConflictUpdate(entry);

  /// Devuelve el grupo por id, o null si no existe localmente.
  Future<FamilyGroupsTableData?> getGroup(String id) =>
      (select(familyGroupsTable)..where((g) => g.id.equals(id)))
          .getSingleOrNull();

  /// Stream del grupo activo (se actualiza si cambia el caché).
  Stream<FamilyGroupsTableData?> watchGroup(String id) =>
      (select(familyGroupsTable)..where((g) => g.id.equals(id)))
          .watchSingleOrNull();

  /// Elimina el grupo y en cascada sus miembros locales.
  Future<int> deleteGroup(String id) =>
      (delete(familyGroupsTable)..where((g) => g.id.equals(id))).go();

  // ── Miembros ──────────────────────────────────────────────────────────────

  /// Inserta o reemplaza un miembro en caché local.
  Future<void> upsertMember(GroupMembersTableCompanion entry) =>
      into(groupMembersTable).insertOnConflictUpdate(entry);

  /// Devuelve todos los miembros de un grupo (consulta única).
  Future<List<GroupMembersTableData>> getMembersForGroup(String groupId) =>
      (select(groupMembersTable)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
          .get();

  /// Stream reactivo de miembros del grupo.
  Stream<List<GroupMembersTableData>> watchMembersForGroup(String groupId) =>
      (select(groupMembersTable)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
          .watch();

  /// Elimina todos los miembros locales de un grupo.
  Future<int> deleteMembersForGroup(String groupId) =>
      (delete(groupMembersTable)..where((m) => m.groupId.equals(groupId))).go();

  /// Reemplaza completamente la lista de miembros de un grupo.
  Future<void> replaceMembersForGroup(
    String groupId,
    List<GroupMembersTableCompanion> members,
  ) async {
    await transaction(() async {
      await deleteMembersForGroup(groupId);
      for (final m in members) {
        await upsertMember(m);
      }
    });
  }
}
