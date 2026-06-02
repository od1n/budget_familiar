import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';

final _log = Logger();

// ── Notifier ──────────────────────────────────────────────────────────────────

class TransferNotifier extends StateNotifier<AsyncValue<void>> {
  TransferNotifier(this._db, this._groupId) : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;

  /// Crea un par de transacciones de transferencia interna (salida + entrada).
  ///
  /// [senderMember] y [receiverMember] son filas de `group_members`.
  /// El usuario activo siempre es el emisor.
  Future<bool> create({
    required GroupMembersTableData senderMember,
    required GroupMembersTableData receiverMember,
    required double amount,
    required String currencyCode,
    double? amountUsdEquivalent,
    required DateTime date,
    String? description,
  }) async {
    if (senderMember.userId == receiverMember.userId) {
      state = AsyncError(
        Exception('El emisor y el receptor no pueden ser la misma persona.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final (outId, inId) = await _db.transactionsDao.insertTransferPair(
        groupId: _groupId,
        senderUserId: senderMember.userId,
        receiverUserId: receiverMember.userId,
        senderPeerName:
            senderMember.displayName ?? senderMember.email ?? 'Usuario',
        receiverPeerName:
            receiverMember.displayName ?? receiverMember.email ?? 'Usuario',
        amount: amount,
        currencyCode: currencyCode,
        amountUsdEquivalent: amountUsdEquivalent,
        date: date,
        description: description,
      );

      // Fire-and-forget: subir ambas filas a Supabase
      _uploadTransferPair(
        outId: outId,
        inId: inId,
        senderMember: senderMember,
        receiverMember: receiverMember,
        amount: amount,
        currencyCode: currencyCode,
        amountUsdEquivalent: amountUsdEquivalent,
        date: date,
        description: description,
      );

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void _uploadTransferPair({
    required String outId,
    required String inId,
    required GroupMembersTableData senderMember,
    required GroupMembersTableData receiverMember,
    required double amount,
    required String currencyCode,
    double? amountUsdEquivalent,
    required DateTime date,
    String? description,
  }) async {
    try {
      final client = supabase;
      if (client.auth.currentUser == null) return;

      final receiverName =
          receiverMember.displayName ?? receiverMember.email ?? 'Usuario';
      final senderName =
          senderMember.displayName ?? senderMember.email ?? 'Usuario';

      // Usamos la RPC create_transfer_pair (SECURITY DEFINER) porque la
      // política INSERT de transactions requiere user_id = auth.uid(), lo que
      // impediría que el emisor inserte la fila del receptor directamente.
      await client.rpc('create_transfer_pair', params: {
        'p_out_id': outId,
        'p_in_id': inId,
        'p_group_id': _groupId,
        'p_sender_id': senderMember.userId,
        'p_receiver_id': receiverMember.userId,
        'p_amount': amount,
        'p_currency_code': currencyCode,
        'p_amount_usd': amountUsdEquivalent,
        'p_date': date.toUtc().toIso8601String(),
        'p_description': description,
        'p_out_notes':
            '{"direction":"out","peer_name":"$receiverName","peer_user_id":"${receiverMember.userId}"}',
        'p_in_notes':
            '{"direction":"in","peer_name":"$senderName","peer_user_id":"${senderMember.userId}"}',
      },);

      // Marcar ambas filas locales como sincronizadas
      await _db.transactionsDao.markSynced(outId);
      await _db.transactionsDao.markSynced(inId);
    } catch (e) {
      _log.w('TransferNotifier: error al subir par de transferencia: $e');
      // Las filas quedan is_synced=false.
      // SyncService.syncPendingTransactions las reintentará, pero solo podrá
      // subir la fila del emisor (user_id = auth.uid()). La del receptor
      // llegará al receptor vía syncDown la próxima vez que abra la app.
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final transferNotifierProvider =
    StateNotifierProvider.autoDispose<TransferNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return TransferNotifier(db, groupId);
});
