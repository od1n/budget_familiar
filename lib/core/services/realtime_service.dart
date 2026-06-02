import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import 'supabase_service.dart';

final _log = Logger();

// ── Estado de conexión ────────────────────────────────────────────────────────

enum RealtimeStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

extension RealtimeStatusX on RealtimeStatus {
  bool get isLive => this == RealtimeStatus.connected;

  String get label => switch (this) {
        RealtimeStatus.disconnected => 'Desconectado',
        RealtimeStatus.connecting   => 'Conectando…',
        RealtimeStatus.connected    => 'En vivo',
        RealtimeStatus.reconnecting => 'Reconectando…',
        RealtimeStatus.failed       => 'Usando sync cada 60 s',
      };
}

// ── RealtimeService ───────────────────────────────────────────────────────────

class RealtimeService {
  RealtimeService(this._db);
  final AppDatabase _db;

  RealtimeChannel? _channel;
  String? _confirmedGroupId;
  String? _pendingGroupId;
  bool _isSubscribed = false;
  int _retryCount = 0;
  static const _maxRetries = 3;
  static const _retryDelays = [5, 15, 30];

  Timer? _retryTimer;

  final _statusController = StreamController<RealtimeStatus>.broadcast();
  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  RealtimeStatus _currentStatus = RealtimeStatus.disconnected;
  RealtimeStatus get status => _currentStatus;

  void _setStatus(RealtimeStatus s) {
    if (_currentStatus == s) return;
    _currentStatus = s;
    _statusController.add(s);
    _log.i('RealtimeService: [$s]');
  }

  // ── API pública ─────────────────────────────────────────────────────────────

  void subscribe(String groupId) {
    if (groupId.isEmpty) return;
    if (_confirmedGroupId == groupId && _isSubscribed) return;
    _retryTimer?.cancel();
    _retryCount = 0;
    _pendingGroupId = groupId;
    _doSubscribe(groupId);
  }

  void unsubscribe() {
    _retryTimer?.cancel();
    _removeChannel();
    _confirmedGroupId = null;
    _pendingGroupId = null;
    _isSubscribed = false;
    _retryCount = 0;
    _setStatus(RealtimeStatus.disconnected);
  }

  void dispose() {
    unsubscribe();
    _statusController.close();
  }

  // ── Lógica interna ──────────────────────────────────────────────────────────

  void _doSubscribe(String groupId) {
    _removeChannel();
    _isSubscribed = false;
    _setStatus(_retryCount > 0
        ? RealtimeStatus.reconnecting
        : RealtimeStatus.connecting);

    final channelName = 'rt_tx_${groupId.replaceAll('-', '_')}';
    _log.i('RealtimeService: suscribiendo canal=$channelName '
        '(intento ${_retryCount + 1}/$_maxRetries)');

    _channel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: _handleInsert,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: _handleUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: _handleDelete,
        )
        .subscribe((status, [error]) {
          _log.d('RealtimeService: status=$status error=${error ?? "-"}');
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              _confirmedGroupId = groupId;
              _isSubscribed = true;
              _retryCount = 0;
              _setStatus(RealtimeStatus.connected);
            case RealtimeSubscribeStatus.channelError:
            case RealtimeSubscribeStatus.timedOut:
              _isSubscribed = false;
              if (error != null) _log.w('RealtimeService: $error');
              _scheduleRetry(groupId);
            case RealtimeSubscribeStatus.closed:
              _isSubscribed = false;
              if (_pendingGroupId == groupId) {
                _setStatus(RealtimeStatus.disconnected);
              }
          }
        });
  }

  void _scheduleRetry(String groupId) {
    if (_retryCount >= _maxRetries) {
      _log.w('RealtimeService: max reintentos. Pull 60s activo.');
      _setStatus(RealtimeStatus.failed);
      return;
    }
    final delaySecs = _retryDelays[_retryCount];
    _retryCount++;
    _log.i('RealtimeService: reintentando en ${delaySecs}s '
        '($_retryCount/$_maxRetries)');
    _retryTimer = Timer(Duration(seconds: delaySecs), () {
      if (_pendingGroupId == groupId && !_isSubscribed) {
        _doSubscribe(groupId);
      }
    });
  }

  void _removeChannel() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleInsert(PostgresChangePayload payload) async {
    try {
      await _db.transactionsDao.upsertTransaction(
          _rowToCompanion(payload.newRecord));
      _log.d('RealtimeService: INSERT tx ${payload.newRecord["id"]}');
    } catch (e) {
      _log.w('RealtimeService: error INSERT: $e');
    }
  }

  Future<void> _handleUpdate(PostgresChangePayload payload) async {
    try {
      await _db.transactionsDao.upsertTransaction(
          _rowToCompanion(payload.newRecord));
      _log.d('RealtimeService: UPDATE tx ${payload.newRecord["id"]}');
    } catch (e) {
      _log.w('RealtimeService: error UPDATE: $e');
    }
  }

  Future<void> _handleDelete(PostgresChangePayload payload) async {
    try {
      final id = payload.oldRecord['id'] as String?;
      if (id == null) return;
      await _db.transactionsDao.deleteTransaction(id);
      _log.d('RealtimeService: DELETE tx $id');
    } catch (e) {
      _log.w('RealtimeService: error DELETE: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  TransactionsTableCompanion _rowToCompanion(Map<String, dynamic> row) =>
      TransactionsTableCompanion(
        id:                  Value(row['id'] as String),
        groupId:             Value(row['group_id'] as String),
        userId:              Value(row['user_id'] as String),
        categoryId:          Value(row['category_id'] as String?),
        amount:              Value((row['amount'] as num).toDouble()),
        currencyCode:        Value(row['currency_code'] as String),
        amountUsdEquivalent: Value((row['amount_usd_equivalent'] as num?)?.toDouble()),
        exchangeRateId:      Value(row['exchange_rate_id'] as String?),
        type:                Value(row['type'] as String),
        date:                Value(DateTime.parse(row['date'] as String).toLocal()),
        description:         Value(row['description'] as String?),
        paymentMethod:       Value(row['payment_method'] as String?),
        notes:               Value(row['notes'] as String?),
        linkedTxId:          Value(row['linked_tx_id'] as String?),
        accountId:           Value(row['account_id'] as String?),
        createdAt:           Value(DateTime.parse(row['created_at'] as String).toLocal()),
        updatedAt:           Value(DateTime.parse(row['updated_at'] as String).toLocal()),
        isSynced:            const Value(true),
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = RealtimeService(db);
  ref.onDispose(service.dispose);
  return service;
});

final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) {
  return ref.watch(realtimeServiceProvider).statusStream;
});
