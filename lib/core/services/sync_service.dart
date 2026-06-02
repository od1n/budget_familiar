import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/local/app_database.dart';
import 'supabase_service.dart';

final _log = Logger();

/// Sube / descarga datos entre Supabase y la DB local.
/// Todas las operaciones son fire-and-forget; los errores se loguean pero no
/// se propagan para no interrumpir la UI.
class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  // ── Subida: pendientes locales → Supabase ─────────────────────────────────

  Future<void> syncPendingTransactions() async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;

      final unsynced = await _db.transactionsDao.getUnsynced();
      if (unsynced.isEmpty) return;

      for (final tx in unsynced) {
        try {
          await client.from('transactions').upsert({
            'id': tx.id,
            'group_id': tx.groupId,
            'user_id': tx.userId,
            'category_id': tx.categoryId,
            'amount': tx.amount,
            'currency_code': tx.currencyCode,
            'amount_usd_equivalent': tx.amountUsdEquivalent,
            'exchange_rate_id': tx.exchangeRateId,
            'type': tx.type,
            'date': tx.date.toUtc().toIso8601String(),
            'description': tx.description,
            'payment_method': tx.paymentMethod,
            'notes': tx.notes,
            'linked_tx_id': tx.linkedTxId,
            'account_id': tx.accountId,
            'created_at': tx.createdAt.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
          await _db.transactionsDao.markSynced(tx.id);
        } catch (e) {
          _log.w('SyncService: fallo al subir tx ${tx.id}: $e');
        }
      }
    } catch (e) {
      _log.w('SyncService: error en syncPendingTransactions: $e');
    }
  }

  // ── Membresía familiar ────────────────────────────────────────────────────

  /// Descarga los grupos a los que pertenece el usuario y los cachea en Drift.
  /// Devuelve la lista de group_ids encontrados.
  /// Se llama antes de syncDown para detectar el grupo activo en dispositivos
  /// donde nunca se guardó la preferencia (primer login en desktop).
  Future<List<String>> syncFamilyMembership() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Membresías del usuario actual
      final memberRows = await supabase
          .from('group_members')
          .select('id, group_id, role, display_name, email, joined_at')
          .eq('user_id', user.id);

      if (memberRows.isEmpty) return [];

      final groupIds = memberRows
          .map((r) => r['group_id'] as String)
          .toSet()
          .toList();

      // Datos de los grupos
      final groupRows = await supabase
          .from('family_groups')
          .select()
          .inFilter('id', groupIds);

      for (final row in groupRows) {
        await _db.familyGroupsDao.upsertGroup(
          FamilyGroupsTableCompanion(
            id: Value(row['id'] as String),
            name: Value(row['name'] as String),
            ownerId: Value(row['owner_id'] as String),
            inviteCode: Value(row['invite_code'] as String),
            createdAt: Value(
              DateTime.parse(row['created_at'] as String).toLocal(),
            ),
          ),
        );
      }

      // Todos los miembros de cada grupo (no solo el usuario actual)
      for (final groupId in groupIds) {
        final allMembers = await supabase
            .from('group_members')
            .select()
            .eq('group_id', groupId);

        await _db.familyGroupsDao.replaceMembersForGroup(
          groupId,
          allMembers
              .map(
                (r) => GroupMembersTableCompanion(
                  id: Value(r['id'] as String),
                  groupId: Value(r['group_id'] as String),
                  userId: Value(r['user_id'] as String),
                  role: Value(r['role'] as String? ?? 'member'),
                  displayName: Value(r['display_name'] as String?),
                  email: Value(r['email'] as String?),
                  joinedAt: Value(
                    DateTime.parse(r['joined_at'] as String).toLocal(),
                  ),
                ),
              )
              .toList(),
        );
      }

      _log.i('SyncService: membresía familiar — ${groupIds.length} grupos');
      return groupIds;
    } catch (e) {
      _log.w('SyncService: error en syncFamilyMembership: $e');
      return [];
    }
  }

  // ── Bajada completa al iniciar sesión ─────────────────────────────────────

  /// Descarga transacciones, presupuestos y metas del grupo desde Supabase.
  Future<void> syncDown(String groupId) async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;

      _log.i('SyncService: iniciando sync descendente para groupId=$groupId');

      await Future.wait([
        _syncAccounts(groupId),
        _syncTransactions(groupId),
        _syncBudgets(groupId),
        _syncSavings(groupId),
        _syncCategories(groupId),
        _syncRecurring(groupId),
      ]);

      _log.i('SyncService: sync descendente completado para groupId=$groupId');
    } catch (e) {
      _log.w('SyncService: error en syncDown: $e');
    }
  }

  // ── Transacciones ─────────────────────────────────────────────────────────

  Future<void> _syncTransactions(String groupId) async {
    try {
      final rows = await supabase
          .from('transactions')
          .select()
          .eq('group_id', groupId)
          .order('date', ascending: false);

      if (rows.isEmpty) return;

      int inserted = 0;
      for (final row in rows) {
        try {
          await _db.transactionsDao.upsertTransaction(
            TransactionsTableCompanion(
              id: Value(row['id'] as String),
              groupId: Value(row['group_id'] as String),
              userId: Value(row['user_id'] as String),
              categoryId: Value(row['category_id'] as String?),
              amount: Value((row['amount'] as num).toDouble()),
              currencyCode: Value(row['currency_code'] as String),
              amountUsdEquivalent: Value(
                (row['amount_usd_equivalent'] as num?)?.toDouble(),
              ),
              exchangeRateId: Value(row['exchange_rate_id'] as String?),
              type: Value(row['type'] as String),
              date: Value(DateTime.parse(row['date'] as String).toLocal()),
              description: Value(row['description'] as String?),
              paymentMethod: Value(row['payment_method'] as String?),
              notes: Value(row['notes'] as String?),
              linkedTxId: Value(row['linked_tx_id'] as String?),
              accountId: Value(row['account_id'] as String?),
              createdAt: Value(
                DateTime.parse(row['created_at'] as String).toLocal(),
              ),
              updatedAt: Value(
                DateTime.parse(row['updated_at'] as String).toLocal(),
              ),
              isSynced: const Value(true),
            ),
          );
          inserted++;
        } catch (e) {
          _log.w('SyncService: fallo al insertar tx ${row['id']}: $e');
        }
      }
      _log.i(
        'SyncService: transacciones — $inserted/${rows.length} filas',
      );
    } catch (e) {
      _log.w('SyncService: error en _syncTransactions: $e');
    }
  }

  // ── Presupuestos ──────────────────────────────────────────────────────────

  Future<void> _syncBudgets(String groupId) async {
    try {
      final rows = await supabase
          .from('budgets')
          .select()
          .eq('group_id', groupId);

      if (rows.isEmpty) return;

      for (final row in rows) {
        try {
          await _db.budgetsDao.upsertBudget(
            BudgetsTableCompanion(
              id: Value(row['id'] as String),
              groupId: Value(row['group_id'] as String),
              categoryId: Value(row['category_id'] as String),
              monthlyLimit: Value((row['monthly_limit'] as num).toDouble()),
              currencyCode: Value(
                row['currency_code'] as String? ?? 'USD',
              ),
              updatedAt: Value(
                DateTime.parse(row['updated_at'] as String).toLocal(),
              ),
            ),
          );
        } catch (e) {
          _log.w('SyncService: fallo al insertar budget ${row['id']}: $e');
        }
      }
      _log.i('SyncService: presupuestos — ${rows.length} filas');
    } catch (e) {
      _log.w('SyncService: error en _syncBudgets: $e');
    }
  }

  // ── Metas de ahorro ───────────────────────────────────────────────────────

  Future<void> _syncSavings(String groupId) async {
    try {
      final rows = await supabase
          .from('savings_goals')
          .select()
          .eq('group_id', groupId);

      if (rows.isEmpty) return;

      for (final row in rows) {
        try {
          await _db.savingsGoalsDao.upsertGoal(
            SavingsGoalsTableCompanion(
              id: Value(row['id'] as String),
              groupId: Value(row['group_id'] as String),
              name: Value(row['name'] as String),
              targetAmount: Value((row['target_amount'] as num).toDouble()),
              currentAmount: Value((row['current_amount'] as num? ?? 0).toDouble()),
              currencyCode: Value(row['currency_code'] as String? ?? 'USD'),
              targetDate: Value(
                row['target_date'] != null
                    ? DateTime.parse(row['target_date'] as String).toLocal()
                    : null,
              ),
              iconCode: Value(row['icon_code'] as String? ?? 'savings'),
              createdAt: Value(
                DateTime.parse(row['created_at'] as String).toLocal(),
              ),
              updatedAt: Value(
                DateTime.parse(row['updated_at'] as String).toLocal(),
              ),
            ),
          );
        } catch (e) {
          _log.w('SyncService: fallo al insertar goal ${row['id']}: $e');
        }
      }
      _log.i('SyncService: metas de ahorro — ${rows.length} filas');
    } catch (e) {
      _log.w('SyncService: error en _syncSavings: $e');
    }
  }
  // ── Categorías personalizadas ─────────────────────────────────────────────

  Future<void> _syncCategories(String groupId) async {
    try {
      final rows = await supabase
          .from('categories')
          .select()
          .eq('group_id', groupId)
          .eq('is_system', false);

      if (rows.isEmpty) return;

      for (final row in rows) {
        try {
          await _db.categoriesDao.upsertCategory(
            CategoriesTableCompanion(
              id: Value(row['id'] as String),
              groupId: Value(row['group_id'] as String?),
              name: Value(row['name'] as String),
              iconCode: Value(row['icon_code'] as String),
              colorHex: Value(row['color_hex'] as String),
              type: Value(row['type'] as String),
              isSystem: const Value(false),
              isActive: Value(row['is_active'] as bool? ?? true),
              sortOrder: Value(row['sort_order'] as int? ?? 0),
              createdAt: Value(
                DateTime.parse(row['created_at'] as String).toLocal(),
              ),
            ),
          );
        } catch (e) {
          _log.w('SyncService: fallo al insertar categoría ${row['id']}: $e');
        }
      }
      _log.i('SyncService: categorías — ${rows.length} filas');
    } catch (e) {
      _log.w('SyncService: error en _syncCategories: $e');
    }
  }
  // ── Plantillas recurrentes ────────────────────────────────────────────────

  Future<void> _syncRecurring(String groupId) async {
    try {
      final rows = await supabase
          .from('recurring_transactions')
          .select()
          .eq('group_id', groupId);

      if (rows.isEmpty) return;

      for (final row in rows) {
        try {
          await _db.recurringTransactionsDao.upsert(
            RecurringTransactionsTableCompanion(
              id: Value(row['id'] as String),
              groupId: Value(row['group_id'] as String),
              userId: Value(row['user_id'] as String),
              categoryId: Value(row['category_id'] as String?),
              amount: Value((row['amount'] as num).toDouble()),
              currencyCode: Value(row['currency_code'] as String? ?? 'USD'),
              type: Value(row['type'] as String),
              description: Value(row['description'] as String?),
              frequency: Value(row['frequency'] as String),
              dayOfMonth: Value(row['day_of_month'] as int?),
              nextDueDate: Value(
                DateTime.parse(row['next_due_date'] as String).toLocal(),
              ),
              isActive: Value(row['is_active'] as bool? ?? true),
              createdAt: Value(
                DateTime.parse(row['created_at'] as String).toLocal(),
              ),
            ),
          );
        } catch (e) {
          _log.w('SyncService: fallo al insertar recurrente ${row['id']}: $e');
        }
      }
      _log.i('SyncService: recurrentes — ${rows.length} filas');
    } catch (e) {
      _log.w('SyncService: error en _syncRecurring: $e');
    }
  }

  // ── Cuentas ───────────────────────────────────────────────────────────────

  Future<void> _syncAccounts(String groupId) async {
    try {
      final rows = await supabase
          .from('accounts')
          .select()
          .eq('group_id', groupId);

      for (final row in rows) {
        await _db.accountsDao.upsert(
          AccountsTableCompanion(
            id: Value(row['id'] as String),
            groupId: Value(row['group_id'] as String),
            type: Value(row['type'] as String? ?? 'cash'),
            name: Value(row['name'] as String),
            currencyCode: Value(row['currency_code'] as String),
            initialBalance:
                Value((row['initial_balance'] as num?)?.toDouble() ?? 0.0),
            colorHex: Value(row['color_hex'] as String? ?? '#607D8B'),
            iconCode: Value(
              row['icon_code'] as String? ?? 'account_balance_wallet',
            ),
            isArchived: Value(row['is_archived'] as bool? ?? false),
            isSynced: const Value(true),
            createdAt: Value(
              DateTime.parse(row['created_at'] as String).toLocal(),
            ),
          ),
        );
      }
    } catch (e) {
      _log.w('SyncService: error en _syncAccounts: $e');
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncService(db);
});
