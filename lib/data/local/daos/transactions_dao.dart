import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<TransactionsTableData>> watchByMonth({
    required String groupId,
    required int year,
    required int month,
    int? limit,
  }) {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1).subtract(const Duration(days: 1));
    final q = select(transactionsTable)
      ..where((t) => t.groupId.equals(groupId))
      ..where((t) => t.date.isBetweenValues(firstDay, lastDay))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Future<int> countByMonth({
    required String groupId,
    required int year,
    required int month,
  }) async {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1).subtract(const Duration(days: 1));
    final expr = transactionsTable.id.count();
    final q = selectOnly(transactionsTable)
      ..addColumns([expr])
      ..where(transactionsTable.groupId.equals(groupId))
      ..where(transactionsTable.date.isBetweenValues(firstDay, lastDay));
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<MonthlySummary> getMonthlySummary({
    required String groupId,
    required int year,
    required int month,
  }) async {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1).subtract(const Duration(days: 1));
    final rows = await (select(transactionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.date.isBetweenValues(firstDay, lastDay))
          // Las transferencias internas son neutrales: no afectan el balance
          ..where((t) => t.type.isNotValue('transfer')))
        .get();

    double totalIncome = 0, totalExpense = 0;
    for (final row in rows) {
      final val = row.amountUsdEquivalent ?? row.amount;
      if (row.type == 'income') {
        totalIncome += val;
      } else {
        totalExpense += val;
      }
    }
    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      count: rows.length,
    );
  }

  Future<Map<String, double>> getExpenseByCategory({
    required String groupId,
    required int year,
    required int month,
  }) async {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1).subtract(const Duration(days: 1));
    // type='expense' ya excluye transfers implícitamente, pero se explicita por claridad
    final rows = await (select(transactionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.type.equals('expense'))
          ..where((t) => t.date.isBetweenValues(firstDay, lastDay)))
        .get();

    final Map<String, double> result = {};
    for (final row in rows) {
      final catId = row.categoryId ?? 'uncategorized';
      result[catId] =
          (result[catId] ?? 0) + (row.amountUsdEquivalent ?? row.amount);
    }
    return result;
  }

  Future<List<TransactionsTableData>> getRecent({
    required String groupId,
    int limit = 5,
  }) {
    return (select(transactionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  Future<TransactionsTableData?> getById(String id) =>
      (select(transactionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<TransactionsTableData>> getUnsynced() {
    return (select(transactionsTable)..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> insertTransaction(TransactionsTableCompanion entry) =>
      into(transactionsTable).insert(entry);

  Future<void> updateTransaction(TransactionsTableCompanion entry) =>
      (update(transactionsTable)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteTransaction(String id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Future<void> markSynced(String id) =>
      (update(transactionsTable)..where((t) => t.id.equals(id)))
          .write(const TransactionsTableCompanion(isSynced: Value(true)));

  Future<void> upsertTransaction(TransactionsTableCompanion entry) =>
      into(transactionsTable).insertOnConflictUpdate(entry);

  /// Inserta dos transacciones vinculadas (par de transferencia interna).
  ///
  /// - [senderUserId]: quien envía el dinero.
  /// - [receiverUserId]: quien lo recibe.
  /// - [senderPeerName] / [receiverPeerName]: nombres para mostrar en la UI.
  ///
  /// Ambas filas quedan con `type='transfer'` e `isSynced=false`.
  /// Devuelve los IDs (outTxId, inTxId).
  Future<(String outId, String inId)> insertTransferPair({
    required String groupId,
    required String senderUserId,
    required String receiverUserId,
    required String senderPeerName,
    required String receiverPeerName,
    required double amount,
    required String currencyCode,
    double? amountUsdEquivalent,
    required DateTime date,
    String? description,
  }) async {
    const uuid = Uuid();
    final outId = uuid.v4();
    final inId = uuid.v4();
    final now = DateTime.now();

    final outNotes = jsonEncode({
      'direction': 'out',
      'peer_name': receiverPeerName,
      'peer_user_id': receiverUserId,
    });
    final inNotes = jsonEncode({
      'direction': 'in',
      'peer_name': senderPeerName,
      'peer_user_id': senderUserId,
    });

    await transaction(() async {
      await into(transactionsTable).insert(
        TransactionsTableCompanion(
          id: Value(outId),
          groupId: Value(groupId),
          userId: Value(senderUserId),
          amount: Value(amount),
          currencyCode: Value(currencyCode),
          amountUsdEquivalent: Value(amountUsdEquivalent),
          type: const Value('transfer'),
          date: Value(date),
          description: Value(description),
          notes: Value(outNotes),
          linkedTxId: Value(inId),
          isSynced: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await into(transactionsTable).insert(
        TransactionsTableCompanion(
          id: Value(inId),
          groupId: Value(groupId),
          userId: Value(receiverUserId),
          amount: Value(amount),
          currencyCode: Value(currencyCode),
          amountUsdEquivalent: Value(amountUsdEquivalent),
          type: const Value('transfer'),
          date: Value(date),
          description: Value(description),
          notes: Value(inNotes),
          linkedTxId: Value(outId),
          isSynced: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });

    return (outId, inId);
  }

  // ── Streams reactivos para el dashboard ─────────────────────────────────────

  Stream<MonthlySummary> watchMonthlySummary({
    required String groupId,
    required int year,
    required int month,
  }) =>
      watchByMonth(groupId: groupId, year: year, month: month).map((rows) {
        double totalIncome = 0, totalExpense = 0;
        bool mixedCurrencies = false;
        for (final row in rows) {
          // Las transferencias internas no impactan el balance familiar
          if (row.type == 'transfer') continue;
          if (row.amountUsdEquivalent == null && row.currencyCode != 'USD') {
            mixedCurrencies = true;
          }
          final val = row.amountUsdEquivalent ?? row.amount;
          if (row.type == 'income') {
            totalIncome += val;
          } else {
            totalExpense += val;
          }
        }
        return MonthlySummary(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          balance: totalIncome - totalExpense,
          count: rows.length,
          hasMixedCurrencies: mixedCurrencies,
        );
      });

  Stream<Map<String, double>> watchExpenseByCategory({
    required String groupId,
    required int year,
    required int month,
  }) {
    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1).subtract(const Duration(days: 1));
    // type='expense' ya excluye transfers y income; explícito por legibilidad
    return (select(transactionsTable)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.type.equals('expense'))
          ..where((t) => t.date.isBetweenValues(firstDay, lastDay)))
        .watch()
        .map((rows) {
      final map = <String, double>{};
      for (final row in rows) {
        final catId = row.categoryId ?? 'uncategorized';
        map[catId] =
            (map[catId] ?? 0) + (row.amountUsdEquivalent ?? row.amount);
      }
      return map;
    });
  }

  Stream<List<TransactionsTableData>> watchRecent({
    required String groupId,
    int limit = 5,
  }) =>
      (select(transactionsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();
}

class MonthlySummary {
  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.count,
    this.hasMixedCurrencies = false,
  });
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int count;

  /// `true` cuando al menos una transacción del mes no tiene equivalente USD,
  /// lo que significa que el balance mezcla distintas monedas sin conversión.
  final bool hasMixedCurrencies;
}
