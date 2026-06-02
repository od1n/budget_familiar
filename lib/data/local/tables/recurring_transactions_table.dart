import 'package:drift/drift.dart';

/// Plantillas de transacciones que se generan automáticamente según la
/// frecuencia configurada (alquiler mensual, salario quincenal, etc.).
class RecurringTransactionsTable extends Table {
  @override
  String get tableName => 'recurring_transactions';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id').nullable()();

  RealColumn get amount => real()();
  TextColumn get currencyCode =>
      text().named('currency_code').withDefault(const Constant('USD'))();

  /// 'income' | 'expense'
  TextColumn get type => text()();

  TextColumn get description => text().nullable()();

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly'
  TextColumn get frequency => text()();

  /// Para frecuencia mensual: día del mes en que se genera (1–28).
  /// null = usar el día de next_due_date.
  IntColumn get dayOfMonth => integer().named('day_of_month').nullable()();

  /// Próxima fecha en que debe generarse la transacción.
  DateTimeColumn get nextDueDate => dateTime().named('next_due_date')();

  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
