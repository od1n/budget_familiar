import 'package:drift/drift.dart';

class AccountsTable extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();

  /// 'cash' | 'bank' | 'digital' | 'credit' | 'investment'
  TextColumn get type => text().withDefault(const Constant('cash'))();
  TextColumn get name => text()();
  TextColumn get currencyCode =>
      text().named('currency_code').withLength(min: 3, max: 3)();
  RealColumn get initialBalance =>
      real().named('initial_balance').withDefault(const Constant(0.0))();
  TextColumn get colorHex =>
      text().named('color_hex').withDefault(const Constant('#607D8B'))();
  TextColumn get iconCode =>
      text().named('icon_code').withDefault(const Constant('account_balance_wallet'))();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();
  BoolColumn get isSynced =>
      boolean().named('is_synced').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
