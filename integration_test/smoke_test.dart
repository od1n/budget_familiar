import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:budget_familiar/data/local/app_database.dart';

// ── Smoke test — DB in-memory ───────────────────────────────────────────────
//
// Ejecutar en Windows:
//   flutter test integration_test/smoke_test.dart -d windows \
//     --dart-define=SUPABASE_URL=https://x.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=x

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DB smoke tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('categorías del sistema se crean en seed', (tester) async {
      final cats = await db.categoriesDao.getCategoriesForGroup('');
      expect(cats.length, greaterThanOrEqualTo(10));

      final incomes = cats.where((c) => c.type == 'income');
      final expenses = cats.where((c) => c.type == 'expense');
      expect(incomes, isNotEmpty);
      expect(expenses, isNotEmpty);
    });

    testWidgets('insertar y leer transacción', (tester) async {
      await db.transactionsDao.insertTransaction(
        TransactionsTableCompanion.insert(
          id: 'test-tx-1',
          groupId: 'test-group',
          userId: 'test-user',
          amount: 50.0,
          currencyCode: 'USD',
          type: 'expense',
          date: DateTime(2026, 6, 1),
          description: const Value('Test expense'),
        ),
      );

      final txList = await db.transactionsDao.getRecent(
        groupId: 'test-group',
        limit: 10,
      );
      expect(txList, hasLength(1));
      expect(txList.first.amount, 50.0);
      expect(txList.first.description, 'Test expense');
    });

    testWidgets('insertar y leer meta de ahorro', (tester) async {
      await db.savingsGoalsDao.upsertGoal(
        SavingsGoalsTableCompanion.insert(
          id: 'goal-1',
          groupId: 'test-group',
          name: 'Vacaciones',
          targetAmount: 1000.0,
          currentAmount: const Value(250.0),
        ),
      );

      final goals = await (db.select(db.savingsGoalsTable)
            ..where((t) => t.groupId.equals('test-group')))
          .get();
      expect(goals, hasLength(1));
      expect(goals.first.name, 'Vacaciones');
      expect(goals.first.currentAmount, 250.0);
    });

    testWidgets('insertar y leer inversión', (tester) async {
      await db.investmentsDao.upsertInvestment(
        InvestmentsTableCompanion.insert(
          id: 'inv-1',
          groupId: 'test-group',
          userId: 'test-user',
          name: 'BTC',
          type: const Value('crypto'),
          initialAmount: 500.0,
          currentValue: const Value(620.0),
        ),
      );

      final invs = await db.investmentsDao.getAllInvestments(
        groupId: 'test-group',
      );
      expect(invs, hasLength(1));
      expect(invs.first.name, 'BTC');
      expect(invs.first.currentValue, 620.0);
    });

    testWidgets('presupuesto se inserta y lee', (tester) async {
      final cats = await db.categoriesDao.getCategoriesForGroup('');
      final catId = cats.first.id;

      await db.budgetsDao.upsertBudget(
        BudgetsTableCompanion.insert(
          id: 'bud-1',
          groupId: 'test-group',
          categoryId: catId,
          monthlyLimit: 300.0,
        ),
      );

      final budgetMap = await db.budgetsDao
          .watchBudgetMap(groupId: 'test-group')
          .first;
      expect(budgetMap[catId], 300.0);
    });
  });
}
