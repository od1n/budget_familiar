import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  // ── Consultas de sistema + grupo ──────────────────────────────────────────

  Future<List<CategoriesTableData>> getCategoriesForGroup(String groupId) {
    return (select(categoriesTable)
          ..where((c) => c.groupId.isNull() | c.groupId.equals(groupId))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .get();
  }

  Stream<List<CategoriesTableData>> watchCategoriesForGroup(String groupId) {
    return (select(categoriesTable)
          ..where((c) => c.groupId.isNull() | c.groupId.equals(groupId))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  // ── Solo categorías personalizadas del grupo ──────────────────────────────

  Stream<List<CategoriesTableData>> watchCustomCategoriesForGroup(
    String groupId,
  ) {
    return (select(categoriesTable)
          ..where((c) => c.groupId.equals(groupId))
          ..where((c) => c.isSystem.equals(false))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.createdAt),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  // ── CRUD de categorías personalizadas ─────────────────────────────────────

  Future<CategoriesTableData> createCustomCategory({
    required String groupId,
    required String name,
    required String iconCode,
    required String colorHex,
    required String type,
  }) async {
    final id = const Uuid().v4();
    final entry = CategoriesTableCompanion.insert(
      id: id,
      groupId: Value(groupId),
      name: name,
      iconCode: iconCode,
      colorHex: colorHex,
      type: type,
      isSystem: const Value(false),
    );
    await into(categoriesTable).insert(entry);
    return (select(categoriesTable)..where((c) => c.id.equals(id))).getSingle();
  }

  /// Soft-delete: marca is_active = false para preservar el historial de
  /// transacciones que ya usan esta categoría.
  Future<void> softDeleteCategory(String id) async {
    await (update(categoriesTable)..where((c) => c.id.equals(id))).write(
      const CategoriesTableCompanion(isActive: Value(false)),
    );
  }

  // ── Upsert genérico ───────────────────────────────────────────────────────

  Future<void> upsertCategory(CategoriesTableCompanion entry) async {
    await into(categoriesTable).insertOnConflictUpdate(entry);
  }

  // ── Seed de categorías del sistema ────────────────────────────────────────

  Future<void> seedSystemCategories() async {
    final system = [
      _sys('sys_food', 'Alimentación', 'restaurant', '#E74C3C', 'expense', 1),
      _sys(
        'sys_transport',
        'Transporte',
        'directions_car',
        '#E67E22',
        'expense',
        2,
      ),
      _sys('sys_services', 'Servicios', 'bolt', '#3498DB', 'expense', 3),
      _sys('sys_health', 'Salud', 'local_hospital', '#2ECC71', 'expense', 4),
      _sys('sys_education', 'Educación', 'school', '#9B59B6', 'expense', 5),
      _sys(
        'sys_entertainment',
        'Entretenimiento',
        'movie',
        '#F39C12',
        'expense',
        6,
      ),
      _sys('sys_clothing', 'Ropa', 'checkroom', '#1ABC9C', 'expense', 7),
      _sys('sys_home', 'Hogar', 'home', '#34495E', 'expense', 8),
      _sys('sys_debt', 'Deudas', 'credit_card', '#C0392B', 'expense', 9),
      _sys(
        'sys_other_exp',
        'Otros gastos',
        'more_horiz',
        '#95A5A6',
        'expense',
        10,
      ),
      _sys('sys_salary', 'Salario', 'work', '#27AE60', 'income', 1),
      _sys('sys_freelance', 'Freelance', 'laptop', '#2980B9', 'income', 2),
      _sys(
        'sys_investments',
        'Ahorros',
        'trending_up',
        '#8E44AD',
        'income',
        3,
      ),
      _sys(
        'sys_other_inc',
        'Otros ingresos',
        'attach_money',
        '#16A085',
        'income',
        4,
      ),
    ];
    await batch(
      (b) =>
          b.insertAll(categoriesTable, system, mode: InsertMode.insertOrIgnore),
    );
  }

  CategoriesTableCompanion _sys(
    String id,
    String name,
    String iconCode,
    String colorHex,
    String type,
    int sortOrder,
  ) =>
      CategoriesTableCompanion.insert(
        id: id,
        name: name,
        iconCode: iconCode,
        colorHex: colorHex,
        type: type,
        isSystem: const Value(true),
        sortOrder: Value(sortOrder),
      );
}
