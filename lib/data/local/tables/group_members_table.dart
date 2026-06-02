import 'package:drift/drift.dart';

/// Caché local de los miembros del grupo familiar activo.
class GroupMembersTable extends Table {
  @override
  String get tableName => 'group_members';

  TextColumn get id => text()();
  TextColumn get groupId => text().named('group_id')();
  TextColumn get userId => text().named('user_id')();

  /// 'owner' | 'member'
  TextColumn get role =>
      text().withDefault(const Constant('member'))();

  TextColumn get displayName => text().named('display_name').nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get joinedAt =>
      dateTime().named('joined_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
