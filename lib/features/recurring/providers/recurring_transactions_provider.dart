import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

export '../../../core/services/recurring_service.dart'
    show RecurringService, recurringServiceProvider;

// ── Lista reactiva de plantillas activas ─────────────────────────────────────

final recurringListProvider =
    StreamProvider.autoDispose<List<RecurringTransactionsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  if (groupId.isEmpty) return const Stream.empty();
  return db.recurringTransactionsDao.watchActive(groupId);
});

// ── CRUD ─────────────────────────────────────────────────────────────────────

class RecurringNotifier extends StateNotifier<AsyncValue<void>> {
  RecurringNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  /// Crea una nueva plantilla recurrente.
  Future<bool> create({
    required double amount,
    required String currencyCode,
    required String type,
    required String frequency,
    required DateTime nextDueDate,
    String? categoryId,
    String? description,
    int? dayOfMonth,
  }) async {
    state = const AsyncLoading();
    try {
      final userId = supabase.currentUserId;
      await _db.recurringTransactionsDao.insert(
        RecurringTransactionsTableCompanion(
          id: Value(const Uuid().v4()),
          groupId: Value(_groupId),
          userId: Value(userId),
          categoryId: Value(categoryId),
          amount: Value(amount),
          currencyCode: Value(currencyCode),
          type: Value(type),
          frequency: Value(frequency),
          nextDueDate: Value(nextDueDate),
          dayOfMonth: Value(dayOfMonth),
          description: Value(description),
          isActive: const Value(true),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Actualiza una plantilla existente.
  Future<bool> update({
    required String id,
    required double amount,
    required String currencyCode,
    required String type,
    required String frequency,
    required DateTime nextDueDate,
    String? categoryId,
    String? description,
    int? dayOfMonth,
  }) async {
    state = const AsyncLoading();
    try {
      final userId = supabase.currentUserId;
      await _db.recurringTransactionsDao.update_(
        RecurringTransactionsTableCompanion(
          id: Value(id),
          groupId: Value(_groupId),
          userId: Value(userId),
          categoryId: Value(categoryId),
          amount: Value(amount),
          currencyCode: Value(currencyCode),
          type: Value(type),
          frequency: Value(frequency),
          nextDueDate: Value(nextDueDate),
          dayOfMonth: Value(dayOfMonth),
          description: Value(description),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Activa o desactiva una plantilla sin eliminarla.
  Future<void> toggleActive(String id, {required bool active}) async {
    try {
      if (active) {
        await _db.recurringTransactionsDao.update_(
          RecurringTransactionsTableCompanion(
            id: Value(id),
            isActive: const Value(true),
          ),
        );
      } else {
        await _db.recurringTransactionsDao.deactivate(id);
      }
    } catch (_) {}
  }

  /// Elimina permanentemente una plantilla.
  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _db.recurringTransactionsDao.delete_(id);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final recurringNotifierProvider =
    StateNotifierProvider.autoDispose<RecurringNotifier, AsyncValue<void>>(
        (ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return RecurringNotifier(db, groupId);
});
