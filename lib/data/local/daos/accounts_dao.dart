import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/accounts_table.dart';
import '../tables/transactions_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [AccountsTable, TransactionsTable])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  // ── Queries ──────────────────────────────────────────────────────────────────

  Stream<List<AccountsTableData>> watchAccounts(String groupId) =>
      (select(accountsTable)
            ..where((t) => t.groupId.equals(groupId) & t.isArchived.not())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<List<AccountsTableData>> getAccounts(String groupId) =>
      (select(accountsTable)
            ..where((t) => t.groupId.equals(groupId) & t.isArchived.not()))
          .get();

  Future<AccountsTableData?> getAccount(String id) =>
      (select(accountsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // ── Balance calculado ─────────────────────────────────────────────────────

  /// Suma de transacciones asociadas a [accountId]:
  ///   income  → +amount
  ///   expense → -amount
  ///   transfer direction=in  → +amount
  ///   transfer direction=out → -amount
  Future<double> getBalance(String accountId) async {
    final account = await getAccount(accountId);
    if (account == null) return 0.0;

    final txs = await (select(transactionsTable)
          ..where((t) => t.accountId.equals(accountId)))
        .get();

    double balance = account.initialBalance;
    for (final tx in txs) {
      if (tx.type == 'income') {
        balance += tx.amount;
      } else if (tx.type == 'expense') {
        balance -= tx.amount;
      } else if (tx.type == 'transfer') {
        // Leer dirección desde notes JSON
        final notes = tx.notes;
        if (notes != null && notes.contains('"direction":"out"')) {
          balance -= tx.amount;
        } else if (notes != null && notes.contains('"direction":"in"')) {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  // ── Mutaciones ────────────────────────────────────────────────────────────

  Future<AccountsTableData> insert({
    required String groupId,
    required String name,
    required String type,
    required String currencyCode,
    double initialBalance = 0.0,
    String colorHex = '#607D8B',
    String iconCode = 'account_balance_wallet',
  }) async {
    final id = const Uuid().v4();
    final companion = AccountsTableCompanion.insert(
      id: id,
      groupId: groupId,
      name: name,
      type: Value(type),
      currencyCode: currencyCode,
      initialBalance: Value(initialBalance),
      colorHex: Value(colorHex),
      iconCode: Value(iconCode),
    );
    await into(accountsTable).insert(companion);
    return (await getAccount(id))!;
  }

  Future<void> update_(AccountsTableData data) =>
      (update(accountsTable)..where((t) => t.id.equals(data.id)))
          .write(data.toCompanion(true));

  Future<void> archive(String id) =>
      (update(accountsTable)..where((t) => t.id.equals(id)))
          .write(const AccountsTableCompanion(isArchived: Value(true)));

  Future<void> delete_(String id) =>
      (delete(accountsTable)..where((t) => t.id.equals(id))).go();

  Future<void> upsert(AccountsTableCompanion companion) =>
      into(accountsTable).insertOnConflictUpdate(companion);

  Future<void> markSynced(String id) =>
      (update(accountsTable)..where((t) => t.id.equals(id)))
          .write(const AccountsTableCompanion(isSynced: Value(true)));

  Future<List<AccountsTableData>> getPendingSync() =>
      (select(accountsTable)..where((t) => t.isSynced.not())).get();
}
