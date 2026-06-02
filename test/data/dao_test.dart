import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/data/local/app_database.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _group = 'group-001';
const _user = 'user-001';

TransactionsTableCompanion _tx({
  required String id,
  required String type,
  required double amount,
  required DateTime date,
  String? categoryId,
  String? accountId,
  String? notes,
  double? amountUsdEquivalent,
}) =>
    TransactionsTableCompanion(
      id: Value(id),
      groupId: const Value(_group),
      userId: const Value(_user),
      type: Value(type),
      amount: Value(amount),
      currencyCode: const Value('USD'),
      amountUsdEquivalent: Value(amountUsdEquivalent),
      date: Value(date),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      notes: Value(notes),
      isSynced: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await db.executor.ensureOpen(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── TransactionsDao.getMonthlySummary ─────────────────────────────────────

  group('TransactionsDao.getMonthlySummary', () {
    test('sin transacciones → balance 0, count 0', () async {
      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 0.0);
      expect(s.totalExpense, 0.0);
      expect(s.balance, 0.0);
      expect(s.count, 0);
    });

    test('ingresos y gastos del mes → balance correcto', () async {
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 1500, date: DateTime(2024, 6, 1)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't2', type: 'expense', amount: 300, date: DateTime(2024, 6, 15)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't3', type: 'expense', amount: 200, date: DateTime(2024, 6, 30)),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 1500.0);
      expect(s.totalExpense, 500.0);
      expect(s.balance, 1000.0);
      expect(s.count, 3);
    });

    test('transferencias excluidas del resumen', () async {
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 1000, date: DateTime(2024, 6, 1)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't2',
          type: 'transfer',
          amount: 500,
          date: DateTime(2024, 6, 10),
        ),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 1000.0);
      expect(s.totalExpense, 0.0);
      expect(s.count, 1); // solo el income, la transferencia no cuenta
    });

    test('transacciones de otro mes no afectan el resumen', () async {
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 1000, date: DateTime(2024, 6, 1)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't2', type: 'income', amount: 9999, date: DateTime(2024, 7, 1)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't3', type: 'income', amount: 9999, date: DateTime(2024, 5, 31)),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 1000.0);
      expect(s.count, 1);
    });

    test('transacciones de otro grupo no afectan el resumen', () async {
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 1000, date: DateTime(2024, 6, 1)),
      );
      await db.transactionsDao.insertTransaction(
        TransactionsTableCompanion(
          id: const Value('t2'),
          groupId: const Value('otro-grupo'),
          userId: const Value(_user),
          type: const Value('income'),
          amount: const Value(9999),
          currencyCode: const Value('USD'),
          date: Value(DateTime(2024, 6, 5)),
          isSynced: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 1000.0);
    });

    test('usa amountUsdEquivalent cuando está disponible', () async {
      // Transacción en VES con equivalente USD
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'expense',
          amount: 36500, // VES
          amountUsdEquivalent: 50.0, // USD equivalente
          date: DateTime(2024, 6, 1),
        ),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalExpense, 50.0); // usa el equivalente USD
    });

    test('diciembre: último día es el 31', () async {
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'income',
          amount: 100,
          date: DateTime(2024, 12, 31),
        ),
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't2',
          type: 'income',
          amount: 9999,
          date: DateTime(2025, 1, 1), // siguiente mes
        ),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 12,
      );
      expect(s.count, 1);
      expect(s.totalIncome, 100.0);
    });
  });

  // ── TransactionsDao.insertTransferPair ────────────────────────────────────

  group('TransactionsDao.insertTransferPair', () {
    test('crea exactamente dos transacciones', () async {
      await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'María',
        receiverPeerName: 'Juan',
        amount: 100.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      final all = await db.transactionsDao.getRecent(groupId: _group, limit: 10);
      expect(all.length, 2);
    });

    test('ambas transacciones son tipo transfer', () async {
      await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'María',
        receiverPeerName: 'Juan',
        amount: 100.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      final all = await db.transactionsDao.getRecent(groupId: _group, limit: 10);
      expect(all.every((t) => t.type == 'transfer'), true);
    });

    test('IDs devueltos son distintos y coinciden con las transacciones', () async {
      final (outId, inId) = await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'María',
        receiverPeerName: 'Juan',
        amount: 50.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      expect(outId, isNot(inId));
      final out = await db.transactionsDao.getById(outId);
      final inn = await db.transactionsDao.getById(inId);
      expect(out, isNotNull);
      expect(inn, isNotNull);
    });

    test('linkedTxId se cruza correctamente', () async {
      final (outId, inId) = await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'María',
        receiverPeerName: 'Juan',
        amount: 75.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      final out = await db.transactionsDao.getById(outId);
      final inn = await db.transactionsDao.getById(inId);
      expect(out!.linkedTxId, inId);
      expect(inn!.linkedTxId, outId);
    });

    test('notes contienen dirección correcta', () async {
      final (outId, inId) = await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'María',
        receiverPeerName: 'Juan',
        amount: 100.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      final out = await db.transactionsDao.getById(outId);
      final inn = await db.transactionsDao.getById(inId);
      expect(out!.notes, contains('"direction":"out"'));
      expect(inn!.notes, contains('"direction":"in"'));
    });

    test('transferencia NO afecta getMonthlySummary', () async {
      await db.transactionsDao.insertTransferPair(
        groupId: _group,
        senderUserId: 'user-a',
        receiverUserId: 'user-b',
        senderPeerName: 'A',
        receiverPeerName: 'B',
        amount: 500.0,
        currencyCode: 'USD',
        date: DateTime(2024, 6, 1),
      );

      final s = await db.transactionsDao.getMonthlySummary(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(s.totalIncome, 0.0);
      expect(s.totalExpense, 0.0);
      expect(s.balance, 0.0);
    });
  });

  // ── AccountsDao.getBalance ────────────────────────────────────────────────

  group('AccountsDao.getBalance', () {
    test('cuenta inexistente → 0.0', () async {
      final balance = await db.accountsDao.getBalance('id-inexistente');
      expect(balance, 0.0);
    });

    test('sin transacciones → solo initialBalance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta principal',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 1000.0,
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 1000.0);
    });

    test('income suma al balance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 500.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'income',
          amount: 300.0,
          date: DateTime(2024, 6, 1),
          accountId: account.id,
        ),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 800.0);
    });

    test('expense resta del balance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 1000.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'expense',
          amount: 250.0,
          date: DateTime(2024, 6, 1),
          accountId: account.id,
        ),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 750.0);
    });

    test('transfer-out resta del balance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta A',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 1000.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'transfer',
          amount: 200.0,
          date: DateTime(2024, 6, 1),
          accountId: account.id,
          notes: '{"direction":"out","peer_name":"B","peer_user_id":"u2"}',
        ),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 800.0);
    });

    test('transfer-in suma al balance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta B',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 200.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'transfer',
          amount: 150.0,
          date: DateTime(2024, 6, 1),
          accountId: account.id,
          notes: '{"direction":"in","peer_name":"A","peer_user_id":"u1"}',
        ),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 350.0);
    });

    test('balance negativo posible', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Tarjeta de crédito',
        type: 'credit',
        currencyCode: 'USD',
        initialBalance: 0.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(
          id: 't1',
          type: 'expense',
          amount: 500.0,
          date: DateTime(2024, 6, 1),
          accountId: account.id,
        ),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, -500.0);
    });

    test('múltiples transacciones acumuladas correctamente', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 0.0,
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 2000, date: DateTime(2024, 6, 1), accountId: account.id),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't2', type: 'expense', amount: 500, date: DateTime(2024, 6, 5), accountId: account.id),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't3', type: 'expense', amount: 300, date: DateTime(2024, 6, 10), accountId: account.id),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't4', type: 'income', amount: 100, date: DateTime(2024, 6, 15), accountId: account.id),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 1300.0); // 0 + 2000 - 500 - 300 + 100
    });

    test('transacciones sin accountId no afectan el balance', () async {
      final account = await db.accountsDao.insert(
        groupId: _group,
        name: 'Cuenta',
        type: 'checking',
        currencyCode: 'USD',
        initialBalance: 500.0,
      );
      // Transacción sin accountId (no asignada a ninguna cuenta)
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'expense', amount: 9999, date: DateTime(2024, 6, 1)),
      );

      final balance = await db.accountsDao.getBalance(account.id);
      expect(balance, 500.0);
    });
  });

  // ── TransactionsDao.countByMonth ──────────────────────────────────────────

  group('TransactionsDao.countByMonth', () {
    test('mes sin transacciones → 0', () async {
      final count = await db.transactionsDao.countByMonth(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(count, 0);
    });

    test('cuenta solo las del mes y grupo correcto', () async {
      await db.transactionsDao.insertTransaction(
        _tx(id: 't1', type: 'income', amount: 100, date: DateTime(2024, 6, 1)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't2', type: 'expense', amount: 50, date: DateTime(2024, 6, 15)),
      );
      await db.transactionsDao.insertTransaction(
        _tx(id: 't3', type: 'income', amount: 100, date: DateTime(2024, 7, 1)), // otro mes
      );

      final count = await db.transactionsDao.countByMonth(
        groupId: _group,
        year: 2024,
        month: 6,
      );
      expect(count, 2);
    });
  });
}
