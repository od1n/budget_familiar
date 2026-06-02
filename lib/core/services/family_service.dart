import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../../data/local/app_database.dart';
import 'supabase_service.dart';

final _log = Logger();

// ── Modelos de resultado ────────────────────────────────────────────────────

class GroupResult {
  const GroupResult({
    required this.group,
    required this.members,
  });
  final FamilyGroupsTableData group;
  final List<GroupMembersTableData> members;
}

// ── FamilyService ───────────────────────────────────────────────────────────

/// Interactúa con Supabase para crear/unirse/salir de grupos familiares
/// y sincroniza el resultado en la caché local (Drift).
///
/// Todos los métodos lanzan excepción en caso de error (el caller decide
/// cómo mostrar el mensaje al usuario).
class FamilyService {
  FamilyService(this._db);
  final AppDatabase _db;

  // ── Crear grupo ───────────────────────────────────────────────────────────

  /// Crea un grupo nuevo en Supabase, cachea localmente y devuelve el resultado.
  /// El invite_code lo genera el trigger de Supabase (pasa vacío).
  Future<GroupResult> createGroup(String name) async {
    final userId = supabase.currentUserId;

    _log.i('FamilyService: creando grupo "$name" para userId=$userId');

    // Usar RPC SECURITY DEFINER — evita problemas de RLS en cliente Android.
    // El trigger genera invite_code y agrega al owner como miembro.
    final created = await supabase
        .rpc('create_family_group', params: {'p_name': name.trim()})
        .single();

    final groupId = created['id'] as String;

    // Descargar miembros (el trigger habrá insertado al owner)
    final membersRaw = await supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    // Cachear localmente
    final groupData = _groupFromRow(created);
    await _db.familyGroupsDao.upsertGroup(_groupCompanion(groupData));

    final members = membersRaw.map(_memberFromRow).toList();
    await _db.familyGroupsDao.replaceMembersForGroup(
      groupId,
      members.map(_memberCompanion).toList(),
    );

    _log.i('FamilyService: grupo creado — id=$groupId '
        'invite=${groupData.inviteCode}');

    return GroupResult(group: groupData, members: members);
  }

  // ── Unirse con código ─────────────────────────────────────────────────────

  /// Une al usuario a un grupo validando el invite_code vía RPC segura.
  /// La RPC `join_group_by_invite` valida el código server-side antes de
  /// insertar, previniendo que usuarios adivinen group_id directamente.
  Future<GroupResult> joinGroupByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    _log.i('FamilyService: uniéndose al grupo con código $cleanCode');

    // 1. Llamar RPC segura — valida invite_code y hace INSERT server-side.
    //    Lanza excepción si el código es inválido.
    await supabase.rpc(
      'join_group_by_invite',
      params: {'p_invite_code': cleanCode},
    );

    // 2. Buscar el grupo (para caché local y datos de retorno)
    final groups = await supabase
        .from('family_groups')
        .select()
        .eq('invite_code', cleanCode)
        .limit(1);

    if (groups.isEmpty) {
      throw Exception('No se pudo obtener el grupo tras unirse.');
    }

    final groupRow = groups.first;
    final groupId = groupRow['id'] as String;

    // 4. Descargar lista completa de miembros
    final membersRaw = await supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    // 5. Cachear localmente
    final groupData = _groupFromRow(groupRow);
    await _db.familyGroupsDao.upsertGroup(_groupCompanion(groupData));

    final members = membersRaw.map(_memberFromRow).toList();
    await _db.familyGroupsDao.replaceMembersForGroup(
      groupId,
      members.map(_memberCompanion).toList(),
    );

    _log.i('FamilyService: unido al grupo ${groupData.name} (id=$groupId)');

    return GroupResult(group: groupData, members: members);
  }

  // ── Obtener miembros ──────────────────────────────────────────────────────

  /// Refresca la lista de miembros desde Supabase y actualiza caché.
  Future<List<GroupMembersTableData>> refreshMembers(String groupId) async {
    final rows = await supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    final members = rows.map(_memberFromRow).toList();
    await _db.familyGroupsDao.replaceMembersForGroup(
      groupId,
      members.map(_memberCompanion).toList(),
    );
    return members;
  }

  // ── Transferir administración ─────────────────────────────────────────────

  /// Transfiere el rol de owner al miembro indicado.
  /// Solo puede ejecutarlo el owner actual.
  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    final userId = supabase.currentUserId;

    _log.i('FamilyService: transfiriendo ownership de $groupId → $newOwnerId');

    // Actualizar owner en family_groups
    await supabase
        .from('family_groups')
        .update({'owner_id': newOwnerId})
        .eq('id', groupId);

    // Actualizar roles en group_members (requiere policy UPDATE en Supabase)
    await supabase
        .from('group_members')
        .update({'role': 'owner'})
        .eq('group_id', groupId)
        .eq('user_id', newOwnerId);

    await supabase
        .from('group_members')
        .update({'role': 'member'})
        .eq('group_id', groupId)
        .eq('user_id', userId);

    // Actualizar caché local
    final group = await _db.familyGroupsDao.getGroup(groupId);
    if (group != null) {
      await _db.familyGroupsDao.upsertGroup(
        _groupCompanion(
          FamilyGroupsTableData(
            id: group.id,
            name: group.name,
            ownerId: newOwnerId,
            inviteCode: group.inviteCode,
            createdAt: group.createdAt,
          ),
        ),
      );
    }
    await refreshMembers(groupId);

    _log.i('FamilyService: ownership transferido correctamente');
  }

  // ── Salir del grupo ───────────────────────────────────────────────────────

  /// El usuario actual sale del grupo. Si era owner y hay otros miembros,
  /// lanza excepción (debe transferir ownership primero).
  Future<void> leaveGroup(String groupId) async {
    final userId = supabase.currentUserId;

    _log.i('FamilyService: saliendo del grupo $groupId');

    // Verificar si es owner con otros miembros
    final groupRow = await supabase
        .from('family_groups')
        .select('owner_id')
        .eq('id', groupId)
        .single();

    if (groupRow['owner_id'] == userId) {
      final count = await supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId);
      if (count.length > 1) {
        throw Exception(
          'Eres el administrador del grupo. '
          'Transfiere la administración antes de salir.',
        );
      }
      // Es el único miembro → eliminar el grupo completo
      await supabase.from('family_groups').delete().eq('id', groupId);
    } else {
      // Solo eliminar la membresía
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    }

    // Limpiar caché local
    await _db.familyGroupsDao.deleteMembersForGroup(groupId);
    await _db.familyGroupsDao.deleteGroup(groupId);

    _log.i('FamilyService: salida del grupo $groupId completada');
  }

  // ── Helpers de mapeo ──────────────────────────────────────────────────────

  FamilyGroupsTableData _groupFromRow(Map<String, dynamic> row) =>
      FamilyGroupsTableData(
        id: row['id'] as String,
        name: row['name'] as String,
        ownerId: row['owner_id'] as String,
        inviteCode: row['invite_code'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  FamilyGroupsTableCompanion _groupCompanion(FamilyGroupsTableData g) =>
      FamilyGroupsTableCompanion(
        id: Value(g.id),
        name: Value(g.name),
        ownerId: Value(g.ownerId),
        inviteCode: Value(g.inviteCode),
        createdAt: Value(g.createdAt),
      );

  GroupMembersTableData _memberFromRow(dynamic rawRow) {
    final row = rawRow as Map<String, dynamic>;
    return GroupMembersTableData(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      userId: row['user_id'] as String,
      role: row['role'] as String? ?? 'member',
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
      joinedAt: DateTime.parse(row['joined_at'] as String).toLocal(),
    );
  }

  GroupMembersTableCompanion _memberCompanion(GroupMembersTableData m) =>
      GroupMembersTableCompanion(
        id: Value(m.id),
        groupId: Value(m.groupId),
        userId: Value(m.userId),
        role: Value(m.role),
        displayName: Value(m.displayName),
        email: Value(m.email),
        joinedAt: Value(m.joinedAt),
      );
}
