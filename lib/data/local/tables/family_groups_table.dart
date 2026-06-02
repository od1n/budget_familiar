import 'package:drift/drift.dart';

/// Caché local del grupo familiar al que pertenece el usuario.
/// Solo se almacena el grupo activo; la fuente de verdad es Supabase.
class FamilyGroupsTable extends Table {
  @override
  String get tableName => 'family_groups';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get inviteCode => text().named('invite_code')();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
