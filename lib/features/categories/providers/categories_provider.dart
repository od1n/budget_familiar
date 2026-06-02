import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

final _log = Logger();

// ── Stream de categorías personalizadas del grupo activo ─────────────────────

final customCategoriesProvider =
    StreamProvider.autoDispose<List<CategoriesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.categoriesDao.watchCustomCategoriesForGroup(groupId);
});

// ── Notifier de CRUD ─────────────────────────────────────────────────────────

class CategoriesNotifier extends StateNotifier<AsyncValue<void>> {
  CategoriesNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  Future<CategoriesTableData?> create({
    required String name,
    required String iconCode,
    required String colorHex,
    required String type,
  }) async {
    state = const AsyncLoading();
    try {
      final cat = await _db.categoriesDao.createCustomCategory(
        groupId: _groupId,
        name: name,
        iconCode: iconCode,
        colorHex: colorHex,
        type: type,
      );

      // Sincronizar con Supabase (fire-and-forget; no bloquea la UI)
      _upsertToSupabase(cat).catchError((e) {
        _log.w('CategoriesNotifier: fallo al sincronizar categoría: $e');
      });

      state = const AsyncData(null);
      return cat;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _db.categoriesDao.softDeleteCategory(id);

      // Reflejar soft-delete en Supabase
      _softDeleteInSupabase(id).catchError((e) {
        _log.w('CategoriesNotifier: fallo al sincronizar eliminación: $e');
      });

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── Helpers Supabase ───────────────────────────────────────────────────────

  Future<void> _upsertToSupabase(CategoriesTableData cat) async {
    if (!supabase.isAuthenticated) return;
    await supabase.from('categories').upsert({
      'id': cat.id,
      'group_id': _groupId,
      'name': cat.name,
      'icon_code': cat.iconCode,
      'color_hex': cat.colorHex,
      'type': cat.type,
      'is_system': false,
      'is_active': true,
      'sort_order': cat.sortOrder,
      'created_at': cat.createdAt.toUtc().toIso8601String(),
    });
  }

  Future<void> _softDeleteInSupabase(String id) async {
    if (!supabase.isAuthenticated) return;
    await supabase
        .from('categories')
        .update({'is_active': false})
        .eq('id', id);
  }
}

final categoriesNotifierProvider =
    StateNotifierProvider.autoDispose<CategoriesNotifier, AsyncValue<void>>(
        (ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return CategoriesNotifier(db, groupId);
});
