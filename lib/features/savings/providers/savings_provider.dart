import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

final _log = Logger();

/// Stream reactivo de metas de ahorro del grupo activo.
final savingsGoalsStreamProvider =
    StreamProvider<List<SavingsGoalsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.savingsGoalsDao.watchGoals(groupId: groupId);
});

/// Notifier para operaciones CRUD sobre metas de ahorro.
class SavingsGoalNotifier extends StateNotifier<AsyncValue<void>> {
  SavingsGoalNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  Future<void> create({
    required String name,
    required double targetAmount,
    String currencyCode = 'USD',
    DateTime? targetDate,
    String iconCode = 'savings',
  }) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();

      await _db.savingsGoalsDao.upsertGoal(
        SavingsGoalsTableCompanion(
          id: Value(id),
          groupId: Value(_groupId),
          name: Value(name),
          targetAmount: Value(targetAmount),
          currentAmount: const Value(0),
          currencyCode: Value(currencyCode),
          targetDate: Value(targetDate),
          iconCode: Value(iconCode),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      _uploadGoalCreate(
        id: id,
        name: name,
        targetAmount: targetAmount,
        currentAmount: 0,
        currencyCode: currencyCode,
        targetDate: targetDate,
        iconCode: iconCode,
        createdAt: now,
        updatedAt: now,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> update({
    required String id,
    required String name,
    required double targetAmount,
    required String currencyCode,
    DateTime? targetDate,
    String? iconCode,
  }) async {
    try {
      await _db.savingsGoalsDao.updateGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        currencyCode: currencyCode,
        targetDate: targetDate,
        iconCode: iconCode,
      );

      _uploadGoalPatch(
        id,
        name: name,
        targetAmount: targetAmount,
        currencyCode: currencyCode,
        targetDate: targetDate,
        iconCode: iconCode,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addAmount({
    required String id,
    required double currentAmount,
    required double addValue,
    required double targetAmount,
  }) async {
    try {
      final newAmount = (currentAmount + addValue).clamp(0, targetAmount);
      await _db.savingsGoalsDao.updateCurrentAmount(
        id: id,
        newAmount: newAmount.toDouble(),
      );

      _uploadGoalPatch(id, currentAmount: newAmount.toDouble());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateInflationRate({
    required String id,
    required double? monthlyRate,
  }) async {
    try {
      await _db.savingsGoalsDao.updateInflationRate(
        id: id,
        monthlyRate: monthlyRate,
      );
      _uploadGoalPatch(id, inflationRateMonthly: monthlyRate);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _db.savingsGoalsDao.deleteGoal(id);
      _deleteGoalRemote(id);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Helpers Supabase ─────────────────────────────────────────────────────

  void _uploadGoalCreate({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required String currencyCode,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? targetDate,
    String? iconCode,
  }) {
    final client = supabase;
    if (client.auth.currentUser == null) return;
    client.from('savings_goals').upsert({
      'id': id,
      'group_id': _groupId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'currency_code': currencyCode,
      if (targetDate != null) 'target_date': targetDate.toIso8601String(),
      'icon_code': iconCode ?? 'savings',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    }).then((_) {
      _log.d('SavingsGoalNotifier: meta $id creada en Supabase');
    }).catchError((e) {
      _log.w('SavingsGoalNotifier: error al crear meta $id: $e');
    });
  }

  void _uploadGoalPatch(
    String id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? currencyCode,
    DateTime? targetDate,
    String? iconCode,
    bool clearTargetDate = false,
    double? inflationRateMonthly,
    bool clearInflation = false,
  }) {
    final client = supabase;
    if (client.auth.currentUser == null) return;
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (iconCode != null) 'icon_code': iconCode,
      if (inflationRateMonthly != null)
        'inflation_rate_monthly': inflationRateMonthly
      else if (clearInflation) 'inflation_rate_monthly': null,
      if (targetDate != null)
        'target_date': targetDate.toIso8601String()
      else if (clearTargetDate)
        'target_date': null,
    };
    client.from('savings_goals').update(patch).eq('id', id).then((_) {
      _log.d('SavingsGoalNotifier: meta $id actualizada en Supabase');
    }).catchError((e) {
      _log.w('SavingsGoalNotifier: error al actualizar meta $id: $e');
    });
  }

  void _deleteGoalRemote(String id) {
    final client = supabase;
    if (client.auth.currentUser == null) return;
    client.from('savings_goals').delete().eq('id', id).then((_) {
      _log.d('SavingsGoalNotifier: meta $id eliminada de Supabase');
    }).catchError((e) {
      _log.w('SavingsGoalNotifier: error al eliminar meta $id: $e');
    });
  }
}

final savingsGoalNotifierProvider =
    StateNotifierProvider<SavingsGoalNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return SavingsGoalNotifier(db, groupId);
});
