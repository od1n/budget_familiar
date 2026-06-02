import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id').nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconCode => text().named('icon_code')();
  TextColumn get colorHex =>
      text().named('color_hex').withLength(min: 7, max: 7)();
  TextColumn get type => text()();
  BoolColumn get isSystem =>
      boolean().named('is_system').withDefault(const Constant(false))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
