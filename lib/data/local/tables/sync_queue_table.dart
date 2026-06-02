import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get operation => text()();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get payload => text()();
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}
