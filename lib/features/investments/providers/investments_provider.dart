import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

const _uuid = Uuid();

// ── Stream principal ──────────────────────────────────────────────────────────

final investmentsProvider =
    StreamProvider<List<InvestmentsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  if (groupId.isEmpty) return const Stream.empty();
  return db.investmentsDao.watchActiveInvestments(groupId: groupId);
});

// ── Totales ───────────────────────────────────────────────────────────────────

class InvestmentTotals {
  const InvestmentTotals({
    required this.totalInvested,
    required this.totalCurrentValue,
  });
  final double totalInvested;
  final double totalCurrentValue;

  double get pnl => totalCurrentValue - totalInvested;
  double get pnlPct =>
      totalInvested == 0 ? 0 : (pnl / totalInvested) * 100;
  bool get isProfit => pnl >= 0;
}

final investmentTotalsProvider = Provider<InvestmentTotals>((ref) {
  final investments = ref.watch(investmentsProvider).valueOrNull ?? [];
  final invested = investments.fold<double>(0, (s, i) => s + i.initialAmount);
  final current = investments.fold<double>(
    0,
    (s, i) => s + (i.currentValue ?? i.initialAmount),
  );
  return InvestmentTotals(
    totalInvested: invested,
    totalCurrentValue: current,
  );
});

// ── Notifier CRUD ─────────────────────────────────────────────────────────────

class InvestmentsNotifier extends StateNotifier<AsyncValue<void>> {
  InvestmentsNotifier(this._db, this._groupId, this._userId)
      : super(const AsyncValue.data(null));

  final AppDatabase _db;
  final String _groupId;
  final String _userId;

  Future<void> add({
    required String name,
    required String type,
    required double initialAmount,
    double? currentValue,
    required String currencyCode,
    DateTime? startDate,
    DateTime? maturityDate,
    String? institution,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      await _db.investmentsDao.upsertInvestment(
        InvestmentsTableCompanion.insert(
          id: _uuid.v4(),
          groupId: _groupId,
          userId: _userId,
          name: name.trim(),
          type: Value(type),
          initialAmount: initialAmount,
          currentValue: Value(currentValue),
          currencyCode: Value(currencyCode),
          startDate: Value(startDate),
          maturityDate: Value(maturityDate),
          institution: Value(institution?.trim()),
          notes: Value(notes?.trim()),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String type,
    required double initialAmount,
    double? currentValue,
    required String currencyCode,
    DateTime? startDate,
    DateTime? maturityDate,
    String? institution,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.investmentsDao.upsertInvestment(
        InvestmentsTableCompanion(
          id: Value(id),
          name: Value(name.trim()),
          type: Value(type),
          initialAmount: Value(initialAmount),
          currentValue: Value(currentValue),
          currencyCode: Value(currencyCode),
          startDate: Value(startDate),
          maturityDate: Value(maturityDate),
          institution: Value(institution?.trim()),
          notes: Value(notes?.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> archive(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _db.investmentsDao.archiveInvestment(id),
    );
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _db.investmentsDao.deleteInvestment(id),
    );
  }
}

final investmentsNotifierProvider =
    StateNotifierProvider<InvestmentsNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  final userId = ref.watch(activeGroupIdProvider); // userId viene del auth, pero usamos groupId como referencia
  return InvestmentsNotifier(db, groupId, userId);
});
