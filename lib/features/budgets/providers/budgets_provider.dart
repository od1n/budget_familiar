import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

final _log = Logger();

/// Stream reactivo: mapa categoryId → monthlyLimit del grupo activo.
final budgetMapProvider = StreamProvider<Map<String, double>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.budgetsDao.watchBudgetMap(groupId: groupId);
});

/// Notifier para operaciones sobre presupuestos.
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  BudgetNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  Future<void> setBudget({
    required String categoryId,
    required double monthlyLimit,
    String currencyCode = 'USD',
  }) async {
    state = const AsyncLoading();
    try {
      // Reutiliza el ID existente para evitar duplicados (bug: antes se
      // generaba un UUID nuevo en cada llamada, creando múltiples filas
      // para el mismo categoryId+groupId).
      final existing = await _db.budgetsDao.getForCategory(
        groupId: _groupId,
        categoryId: categoryId,
      );
      final id = existing?.id ?? const Uuid().v4();
      final now = DateTime.now().toUtc();

      await _db.budgetsDao.upsertBudget(
        BudgetsTableCompanion(
          id: Value(id),
          groupId: Value(_groupId),
          categoryId: Value(categoryId),
          monthlyLimit: Value(monthlyLimit),
          currencyCode: Value(currencyCode),
          updatedAt: Value(now),
        ),
      );

      // ── Supabase (fire-and-forget) ─────────────────────────────────────
      _uploadBudget(
        id: id,
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        currencyCode: currencyCode,
        updatedAt: now,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeBudget(String categoryId) async {
    try {
      // Obtiene el ID antes de borrar para poder borrarlo en Supabase
      final existing = await _db.budgetsDao.getForCategory(
        groupId: _groupId,
        categoryId: categoryId,
      );
      await _db.budgetsDao.deleteByCategoryAndGroup(
        groupId: _groupId,
        categoryId: categoryId,
      );
      if (existing != null) {
        _deleteBudgetRemote(existing.id);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Helpers Supabase ─────────────────────────────────────────────────────

  void _uploadBudget({
    required String id,
    required String categoryId,
    required double monthlyLimit,
    required String currencyCode,
    required DateTime updatedAt,
  }) {
    final client = supabase;
    if (client.auth.currentUser == null) return;
    client.from('budgets').upsert({
      'id': id,
      'group_id': _groupId,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
      'currency_code': currencyCode,
      'updated_at': updatedAt.toIso8601String(),
    }).then((_) {
      _log.d('BudgetNotifier: budget $id subido a Supabase');
    }).catchError((e) {
      _log.w('BudgetNotifier: error al subir budget $id: $e');
    });
  }

  void _deleteBudgetRemote(String id) {
    final client = supabase;
    if (client.auth.currentUser == null) return;
    client.from('budgets').delete().eq('id', id).then((_) {
      _log.d('BudgetNotifier: budget $id eliminado de Supabase');
    }).catchError((e) {
      _log.w('BudgetNotifier: error al eliminar budget $id: $e');
    });
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return BudgetNotifier(db, groupId);
});
