import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/family_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';

// ── Clave de SharedPreferences ────────────────────────────────────────────────

String _prefKey(String userId) => 'active_group_$userId';

// ── Provider de inicialización ────────────────────────────────────────────────

/// Valor inicial del grupo activo leído desde SharedPreferences en main.dart
/// antes de montar el árbol de widgets.
/// Se sobreescribe con: groupInitProvider.overrideWithValue(storedGroupId)
/// Si no hay grupo guardado, el valor es '' (modo individual = userId).
final groupInitProvider = Provider<String>((_) => '');

// ── ActiveGroupNotifier ───────────────────────────────────────────────────────

class ActiveGroupNotifier extends StateNotifier<String> {
  ActiveGroupNotifier(super.initialGroupId);

  /// Cambia al grupo indicado y lo persiste en SharedPreferences.
  Future<void> setGroup(String groupId) async {
    state = groupId;
    await _persist(groupId);
  }

  /// Vuelve al modo individual (groupId = userId del usuario actual).
  Future<void> resetToPersonal() async {
    final userId = supabase.currentUserId;
    state = userId;
    await _persist(userId);
  }

  /// Lee el grupo guardado en SharedPreferences y lo aplica.
  /// Se llama en app.dart al detectar signedIn.
  Future<void> restoreFromPrefs() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey(userId));
    if (stored != null && stored.isNotEmpty) {
      state = stored;
    } else {
      state = userId;
    }
  }

  Future<void> _persist(String groupId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(userId), groupId);
  }
}

// ── Providers públicos ────────────────────────────────────────────────────────

/// ID del grupo activo. Se inicializa con el valor leído en main.dart.
/// Si es '' o el usuario no tiene grupo, regresa al userId (modo individual).
final activeGroupIdProvider =
    StateNotifierProvider<ActiveGroupNotifier, String>((ref) {
  final init = ref.watch(groupInitProvider);
  // Si el init está vacío, usar el userId como fallback (modo individual)
  final effective = init.isNotEmpty ? init : _fallbackUserId();
  return ActiveGroupNotifier(effective);
});

String _fallbackUserId() {
  try {
    return supabase.currentUserId;
  } catch (_) {
    return '';
  }
}

// ── FamilyService provider ────────────────────────────────────────────────────

final familyServiceProvider = Provider<FamilyService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FamilyService(db);
});

// ── Stream de miembros del grupo activo ───────────────────────────────────────

final groupMembersProvider =
    StreamProvider<List<GroupMembersTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.familyGroupsDao.watchMembersForGroup(groupId);
});

// ── Datos del grupo activo (caché local) ──────────────────────────────────────

final activeGroupProvider =
    StreamProvider<FamilyGroupsTableData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.familyGroupsDao.watchGroup(groupId);
});
