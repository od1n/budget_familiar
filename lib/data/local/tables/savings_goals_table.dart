import 'package:drift/drift.dart';

class SavingsGoalsTable extends Table {
  @override
  String get tableName => 'savings_goals';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get name => text()();
  RealColumn get targetAmount => real().named('target_amount')();
  RealColumn get currentAmount =>
      real().named('current_amount').withDefault(const Constant(0))();
  TextColumn get currencyCode => text()
      .named('currency_code')
      .withLength(min: 3, max: 3)
      .withDefault(const Constant('USD'))();
  DateTimeColumn get targetDate => dateTime().named('target_date').nullable()();
  TextColumn get iconCode =>
      text().named('icon_code').withDefault(const Constant('savings'))();
  /// Tasa de inflación mensual en % (ej. 4.5). NULL = ajuste desactivado.
  RealColumn get inflationRateMonthly =>
      real().named('inflation_rate_monthly').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
