import 'package:drift/drift.dart';

class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id').nullable()();
  RealColumn get amount => real()();
  TextColumn get currencyCode =>
      text().named('currency_code').withLength(min: 3, max: 3)();
  RealColumn get amountUsdEquivalent =>
      real().named('amount_usd_equivalent').nullable()();
  TextColumn get exchangeRateId =>
      text().named('exchange_rate_id').nullable()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => text().named('payment_method').nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get linkedTxId => text().named('linked_tx_id').nullable()();
  TextColumn get accountId => text().named('account_id').nullable()();
  BoolColumn get isSynced =>
      boolean().named('is_synced').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
