import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/accounts_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/family_groups_dao.dart';
import 'daos/investments_dao.dart';
import 'daos/virtual_envelopes_dao.dart';
import 'daos/recurring_transactions_dao.dart';
import 'daos/savings_goals_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/accounts_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/family_groups_table.dart';
import 'tables/group_members_table.dart';
import 'tables/investments_table.dart';
import 'tables/virtual_envelopes_table.dart';
import 'tables/recurring_transactions_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AccountsTable,
    CategoriesTable,
    TransactionsTable,
    ExchangeRatesTable,
    SyncQueueTable,
    BudgetsTable,
    SavingsGoalsTable,
    FamilyGroupsTable,
    GroupMembersTable,
    RecurringTransactionsTable,
    InvestmentsTable,
    VirtualEnvelopesTable,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    BudgetsDao,
    SavingsGoalsDao,
    FamilyGroupsDao,
    RecurringTransactionsDao,
    InvestmentsDao,
    VirtualEnvelopesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor para tests — usa base de datos en memoria.
  @visibleForTesting
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 9;

  /// Elimina todos los datos del usuario de la base de datos local.
  /// Llamar antes de cerrar sesión por eliminación de cuenta.
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(transactionsTable).go();
      await delete(recurringTransactionsTable).go();
      await delete(budgetsTable).go();
      await delete(savingsGoalsTable).go();
      await delete(accountsTable).go();
      // Categorías personalizadas (las del sistema se conservan por group_id NULL)
      await (delete(categoriesTable)
            ..where((t) => t.isSystem.not()))
          .go();
      await delete(groupMembersTable).go();
      await delete(familyGroupsTable).go();
      await delete(exchangeRatesTable).go();
      await delete(investmentsTable).go();
      await delete(virtualEnvelopesTable).go();
      await delete(syncQueueTable).go();
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await categoriesDao.seedSystemCategories();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // v1 → v2: tablas budgets y savings_goals
          await m.createTable(budgetsTable);
          await m.createTable(savingsGoalsTable);
        }
        if (from < 3) {
          // v2 → v3: tablas family_groups y group_members
          await m.createTable(familyGroupsTable);
          await m.createTable(groupMembersTable);
        }
        if (from < 4) {
          // v3 → v4: tabla recurring_transactions
          await m.createTable(recurringTransactionsTable);
        }
        if (from < 5) {
          // v4 → v5: columna linked_tx_id para transferencias internas
          await m.addColumn(
            transactionsTable,
            transactionsTable.linkedTxId,
          );
        }
        if (from < 6) {
          // v5 → v6: tabla accounts + columna account_id en transactions
          await m.createTable(accountsTable);
          await m.addColumn(
            transactionsTable,
            transactionsTable.accountId,
          );
        }
        if (from < 7) {
          // v6 → v7: tabla investments
          await m.createTable(investmentsTable);
        }
        if (from < 8) {
          // v7 → v8: columna inflation_rate_monthly en savings_goals
          await m.addColumn(
            savingsGoalsTable,
            savingsGoalsTable.inflationRateMonthly,
          );
        }
        if (from < 9) {
          // v8 → v9: tabla virtual_envelopes
          await m.createTable(virtualEnvelopesTable);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget_familiar_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// SQLCipher: para habilitar cifrado en Android/iOS, agregar
// sqlcipher_flutter_libs al pubspec (solo para target móvil, no Windows)
// y descomentar el setup con PRAGMA key en _openConnection.

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider debe ser sobreescrito en main.dart',
  ),
);
