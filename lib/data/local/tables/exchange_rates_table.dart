import 'package:drift/drift.dart';

class ExchangeRatesTable extends Table {
  @override
  String get tableName => 'exchange_rates';

  TextColumn get id => text()();
  TextColumn get fromCurrency =>
      text().named('from_currency').withLength(min: 3, max: 3)();
  TextColumn get toCurrency =>
      text().named('to_currency').withLength(min: 3, max: 3)();
  RealColumn get rate => real()();
  TextColumn get rateType => text().named('rate_type')();
  TextColumn get source => text().nullable()();
  DateTimeColumn get validAt => dateTime().named('valid_at')();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
