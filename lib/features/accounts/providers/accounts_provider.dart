import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

final _log = Logger();

// ── Stream de cuentas activas del grupo ───────────────────────────────────────

final accountsProvider = StreamProvider.autoDispose
    .family<List<AccountsTableData>, String>((ref, groupId) {
  final db = ref.watch(appDatabaseProvider);
  return db.accountsDao.watchAccounts(groupId);
});

/// Acceso rápido con el grupo activo
final activeAccountsProvider =
    StreamProvider.autoDispose<List<AccountsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.accountsDao.watchAccounts(groupId);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class AccountsNotifier extends StateNotifier<AsyncValue<void>> {
  AccountsNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  /// Crea una cuenta y la sube a Supabase.
  Future<AccountsTableData?> create({
    required String name,
    required String type,
    required String currencyCode,
    double initialBalance = 0.0,
    String colorHex = '#607D8B',
    String iconCode = 'account_balance_wallet',
  }) async {
    state = const AsyncLoading();
    try {
      final account = await _db.accountsDao.insert(
        groupId: _groupId,
        name: name,
        type: type,
        currencyCode: currencyCode,
        initialBalance: initialBalance,
        colorHex: colorHex,
        iconCode: iconCode,
      );
      _uploadAccount(account);
      state = const AsyncData(null);
      return account;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> updateAccount(AccountsTableData data) async {
    state = const AsyncLoading();
    try {
      await _db.accountsDao.update_(data);
      _uploadAccount(data);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> archive(String id) async {
    state = const AsyncLoading();
    try {
      await _db.accountsDao.archive(id);
      _patchSupabase(id, {'is_archived': true});
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _db.accountsDao.delete_(id);
      _deleteSupabase(id);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── Supabase helpers (fire-and-forget) ──────────────────────────────────

  void _uploadAccount(AccountsTableData a) async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;
      await client.from('accounts').upsert({
        'id': a.id,
        'group_id': a.groupId,
        'type': a.type,
        'name': a.name,
        'currency_code': a.currencyCode,
        'initial_balance': a.initialBalance,
        'color_hex': a.colorHex,
        'icon_code': a.iconCode,
        'is_archived': a.isArchived,
        'created_at': a.createdAt.toUtc().toIso8601String(),
      });
      await _db.accountsDao.markSynced(a.id);
    } catch (e) {
      _log.w('AccountsNotifier: error al subir cuenta: $e');
    }
  }

  void _patchSupabase(String id, Map<String, dynamic> patch) async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;
      await client.from('accounts').update(patch).eq('id', id);
    } catch (e) {
      _log.w('AccountsNotifier: error al parchear cuenta: $e');
    }
  }

  void _deleteSupabase(String id) async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;
      await client.from('accounts').delete().eq('id', id);
    } catch (e) {
      _log.w('AccountsNotifier: error al borrar cuenta en Supabase: $e');
    }
  }
}

final accountsNotifierProvider =
    StateNotifierProvider.autoDispose<AccountsNotifier, AsyncValue<void>>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    final groupId = ref.watch(activeGroupIdProvider);
    return AccountsNotifier(db, groupId);
  },
);
