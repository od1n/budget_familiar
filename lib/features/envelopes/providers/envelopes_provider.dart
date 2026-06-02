import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';
import '../../../core/services/supabase_service.dart';

const _uuid = Uuid();

// ── Stream ────────────────────────────────────────────────────────────────────

final envelopesProvider =
    StreamProvider<List<VirtualEnvelopesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  if (groupId.isEmpty) return const Stream.empty();
  return db.virtualEnvelopesDao.watchActiveEnvelopes(groupId: groupId);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class EnvelopesNotifier extends StateNotifier<AsyncValue<void>> {
  EnvelopesNotifier(this._db, this._groupId)
      : super(const AsyncValue.data(null));

  final AppDatabase _db;
  final String _groupId;

  Future<void> create({
    required String name,
    required double allocatedAmount,
    required String currencyCode,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? categoryId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      final now = DateTime.now();
      final entry = VirtualEnvelopesTableCompanion.insert(
        id: id,
        groupId: _groupId,
        name: name.trim(),
        allocatedAmount: allocatedAmount,
        currencyCode: Value(currencyCode),
        periodStart: periodStart,
        periodEnd: periodEnd,
        categoryId: Value(categoryId),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await _db.virtualEnvelopesDao.upsertEnvelope(entry);
      _uploadCreate(id: id, name: name, allocated: allocatedAmount,
          currency: currencyCode, start: periodStart, end: periodEnd,
          categoryId: categoryId, now: now);
    });
  }

  Future<void> addSpent({
    required String id,
    required double currentSpent,
    required double add,
  }) async {
    final newSpent = currentSpent + add;
    await _db.virtualEnvelopesDao.updateSpent(id: id, newSpent: newSpent);
    supabase.from('virtual_envelopes')
        .update({'spent_amount': newSpent,
                 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .catchError((_) {});
  }

  Future<void> archive(String id) async {
    await _db.virtualEnvelopesDao.archiveEnvelope(id);
    supabase.from('virtual_envelopes')
        .update({'is_active': false,
                 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .catchError((_) {});
  }

  void _uploadCreate({
    required String id, required String name, required double allocated,
    required String currency, required DateTime start, required DateTime end,
    required DateTime now, String? categoryId,
  }) {
    if (supabase.auth.currentUser == null) return;
    supabase.from('virtual_envelopes').upsert({
      'id': id, 'group_id': _groupId, 'name': name,
      'allocated_amount': allocated, 'spent_amount': 0.0,
      'currency_code': currency,
      'period_start': start.toIso8601String(),
      'period_end': end.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      'is_active': true,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).catchError((_) {});
  }
}

final envelopesNotifierProvider =
    StateNotifierProvider<EnvelopesNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return EnvelopesNotifier(db, groupId);
});
