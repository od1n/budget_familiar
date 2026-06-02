import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/data/local/app_database.dart';

/// Tests de la lógica de serialización/deserialización del BackupService.
/// Usa AppDatabase.memory() para evitar acceso a disco.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _seedCategories(String groupId) async {
    await db.into(db.categoriesTable).insert(
          CategoriesTableCompanion.insert(
            id: 'cat-1',
            groupId: Value(groupId),
            name: 'Test Category',
            iconCode: 'restaurant',
            colorHex: '#FF0000',
            type: 'expense',
          ),
        );
  }

  Future<void> _seedTransactions(String groupId) async {
    await db.into(db.transactionsTable).insert(
          TransactionsTableCompanion.insert(
            id: 'tx-1',
            groupId: groupId,
            userId: 'user-1',
            amount: 42.50,
            currencyCode: 'USD',
            type: 'expense',
            date: DateTime(2026, 6, 1),
            description: const Value('Almuerzo'),
            paymentMethod: const Value('cash'),
          ),
        );
    await db.into(db.transactionsTable).insert(
          TransactionsTableCompanion.insert(
            id: 'tx-2',
            groupId: groupId,
            userId: 'user-1',
            amount: 1500.0,
            currencyCode: 'VES',
            type: 'income',
            date: DateTime(2026, 6, 1),
            description: const Value('Salario'),
          ),
        );
  }

  Future<void> _seedBudgets(String groupId) async {
    await _seedCategories(groupId);
    await db.into(db.budgetsTable).insert(
          BudgetsTableCompanion.insert(
            id: 'bud-1',
            groupId: groupId,
            categoryId: 'cat-1',
            monthlyLimit: 200.0,
          ),
        );
  }

  Future<void> _seedGoals(String groupId) async {
    await db.into(db.savingsGoalsTable).insert(
          SavingsGoalsTableCompanion.insert(
            id: 'goal-1',
            groupId: groupId,
            name: 'Vacaciones',
            targetAmount: 500.0,
            currentAmount: const Value(150.0),
            targetDate: Value(DateTime(2026, 12, 31)),
            inflationRateMonthly: const Value(5.2),
          ),
        );
  }

  Future<void> _seedInvestments(String groupId) async {
    await db.into(db.investmentsTable).insert(
          InvestmentsTableCompanion.insert(
            id: 'inv-1',
            groupId: groupId,
            userId: 'user-1',
            name: 'Depósito a plazo',
            initialAmount: 1000.0,
            currentValue: const Value(1050.0),
            type: const Value('fixed_term'),
          ),
        );
  }

  // ── Gather data ──────────────────────────────────────────────────────────

  /// Reimplementa la lógica de recolección sin depender del BuildContext.
  Future<Map<String, dynamic>> _gatherData(String groupId) async {
    final txRows = await (db.select(db.transactionsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    final catRows = await (db.select(db.categoriesTable)
          ..where(
            (t) => t.groupId.equals(groupId) | t.groupId.isNull(),
          ))
        .get();
    final budgetRows = await (db.select(db.budgetsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    final goalRows = await (db.select(db.savingsGoalsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    final invRows = await (db.select(db.investmentsTable)
          ..where((t) => t.groupId.equals(groupId)))
        .get();

    return {
      'transactions': txRows
          .map((t) => {
                'id': t.id,
                'userId': t.userId,
                'categoryId': t.categoryId,
                'amount': t.amount,
                'currencyCode': t.currencyCode,
                'amountUsdEquivalent': t.amountUsdEquivalent,
                'type': t.type,
                'date': t.date.toIso8601String(),
                'description': t.description,
                'paymentMethod': t.paymentMethod,
                'notes': t.notes,
                'linkedTxId': t.linkedTxId,
                'accountId': t.accountId,
              })
          .toList(),
      'categories': catRows
          .where((c) => !c.isSystem)
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'iconCode': c.iconCode,
                'colorHex': c.colorHex,
                'type': c.type,
                'sortOrder': c.sortOrder,
                'isActive': c.isActive,
              })
          .toList(),
      'budgets': budgetRows
          .map((b) => {
                'id': b.id,
                'categoryId': b.categoryId,
                'monthlyLimit': b.monthlyLimit,
                'currencyCode': b.currencyCode,
              })
          .toList(),
      'savingsGoals': goalRows
          .map((g) => {
                'id': g.id,
                'name': g.name,
                'targetAmount': g.targetAmount,
                'currentAmount': g.currentAmount,
                'currencyCode': g.currencyCode,
                'targetDate': g.targetDate?.toIso8601String(),
                'iconCode': g.iconCode,
                'inflationRateMonthly': g.inflationRateMonthly,
              })
          .toList(),
      'investments': invRows
          .map((i) => {
                'id': i.id,
                'userId': i.userId,
                'name': i.name,
                'type': i.type,
                'initialAmount': i.initialAmount,
                'currentValue': i.currentValue,
                'currencyCode': i.currencyCode,
              })
          .toList(),
    };
  }

  // ── Tests ────────────────────────────────────────────────────────────────

  group('Backup gather', () {
    test('recolecta transacciones del grupo correcto', () async {
      await _seedTransactions('group-A');
      // Insertar una transacción en otro grupo (no debe incluirse)
      await db.into(db.transactionsTable).insert(
            TransactionsTableCompanion.insert(
              id: 'tx-other',
              groupId: 'group-B',
              userId: 'user-2',
              amount: 99.0,
              currencyCode: 'USD',
              type: 'expense',
              date: DateTime(2026, 6, 1),
            ),
          );

      final data = await _gatherData('group-A');
      final txList = data['transactions'] as List;

      expect(txList, hasLength(2));
      expect(txList.every((t) => t['id'] == 'tx-1' || t['id'] == 'tx-2'), true);
    });

    test('excluye categorías del sistema en el backup', () async {
      await _seedCategories('group-A');
      // Las categorías seed del sistema se crean en onCreate

      final data = await _gatherData('group-A');
      final catList = data['categories'] as List;

      // Solo la categoría personalizada, no las del sistema
      expect(catList, hasLength(1));
      expect(catList.first['id'], 'cat-1');
    });

    test('recolecta metas con campo inflación', () async {
      await _seedGoals('group-A');

      final data = await _gatherData('group-A');
      final goals = data['savingsGoals'] as List;

      expect(goals, hasLength(1));
      expect(goals.first['inflationRateMonthly'], 5.2);
      expect(goals.first['currentAmount'], 150.0);
    });

    test('recolecta inversiones', () async {
      await _seedInvestments('group-A');

      final data = await _gatherData('group-A');
      final invs = data['investments'] as List;

      expect(invs, hasLength(1));
      expect(invs.first['name'], 'Depósito a plazo');
      expect(invs.first['currentValue'], 1050.0);
    });
  });

  group('Backup JSON round-trip', () {
    test('serialize → deserialize preserva datos', () async {
      await _seedTransactions('group-A');
      await _seedBudgets('group-A');
      await _seedGoals('group-A');

      final original = await _gatherData('group-A');
      final json = jsonEncode(original);
      final restored = jsonDecode(json) as Map<String, dynamic>;

      expect(
        (restored['transactions'] as List).length,
        (original['transactions'] as List).length,
      );
      expect(
        (restored['budgets'] as List).length,
        (original['budgets'] as List).length,
      );
      expect(
        (restored['savingsGoals'] as List).first['inflationRateMonthly'],
        5.2,
      );
    });

    test('grupo vacío produce listas vacías', () async {
      final data = await _gatherData('nonexistent');

      expect(data['transactions'], isEmpty);
      expect(data['categories'], isEmpty);
      expect(data['budgets'], isEmpty);
      expect(data['savingsGoals'], isEmpty);
      expect(data['investments'], isEmpty);
    });
  });
}
