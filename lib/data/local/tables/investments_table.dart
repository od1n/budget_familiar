import 'package:drift/drift.dart';

class InvestmentsTable extends Table {
  @override
  String get tableName => 'investments';

  TextColumn   get id            => text()();
  TextColumn   get groupId       => text().named('group_id')();
  TextColumn   get userId        => text().named('user_id')();
  TextColumn   get name          => text()();
  TextColumn   get type          => text().withDefault(const Constant('other'))();
  RealColumn   get initialAmount => real().named('initial_amount')();
  RealColumn   get currentValue  => real().named('current_value').nullable()();
  TextColumn   get currencyCode  => text()
      .named('currency_code')
      .withLength(min: 3, max: 3)
      .withDefault(const Constant('USD'))();
  DateTimeColumn get startDate    => dateTime().named('start_date').nullable()();
  DateTimeColumn get maturityDate => dateTime().named('maturity_date').nullable()();
  TextColumn   get institution   => text().nullable()();
  TextColumn   get notes         => text().nullable()();
  BoolColumn   get isActive      => boolean()
      .named('is_active')
      .withDefault(const Constant(true))();
  DateTimeColumn get createdAt   =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt   =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
