import 'package:drift/drift.dart';

class VirtualEnvelopesTable extends Table {
  @override
  String get tableName => 'virtual_envelopes';

  TextColumn   get id              => text()();
  TextColumn   get groupId         => text().named('group_id')();
  TextColumn   get categoryId      => text().named('category_id').nullable()();
  TextColumn   get name            => text()();
  RealColumn   get allocatedAmount => real().named('allocated_amount')();
  RealColumn   get spentAmount     =>
      real().named('spent_amount').withDefault(const Constant(0))();
  TextColumn   get currencyCode    => text()
      .named('currency_code')
      .withLength(min: 3, max: 3)
      .withDefault(const Constant('USD'))();
  DateTimeColumn get periodStart   => dateTime().named('period_start')();
  DateTimeColumn get periodEnd     => dateTime().named('period_end')();
  BoolColumn   get isActive        =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt     =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt     =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
