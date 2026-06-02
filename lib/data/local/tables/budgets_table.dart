import 'package:drift/drift.dart';

/// Límite mensual de gasto por categoría.
/// La restricción UNIQUE (group_id, category_id) se gestiona
/// con insertOnConflictUpdate en el DAO.
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get categoryId => text().named('category_id')();
  RealColumn get monthlyLimit => real().named('monthly_limit')();
  TextColumn get currencyCode => text()
      .named('currency_code')
      .withLength(min: 3, max: 3)
      .withDefault(const Constant('USD'))();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
