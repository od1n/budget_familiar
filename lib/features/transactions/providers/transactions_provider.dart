import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/local/app_database.dart';
import '../../../../core/services/fcm_service.dart';
import '../../budgets/providers/budget_alert_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../../core/services/exchange_rate_service.dart';

// ── Mapa de id de categoría → nombre legible ──────────────────────────────────

String _catName(String id) => switch (id) {
      'sys_food' => 'Alimentación',
      'sys_transport' => 'Transporte',
      'sys_services' => 'Servicios',
      'sys_health' => 'Salud',
      'sys_education' => 'Educación',
      'sys_entertainment' => 'Entretenimiento',
      'sys_clothing' => 'Ropa',
      'sys_home' => 'Hogar',
      'sys_debt' => 'Deudas',
      _ => 'Categoría',
    };

// ── Lista reactiva filtrada por mes (con paginación) ─────────────────────────

const kTxPageSize = 25;

/// Parámetros de consulta: año, mes y límite de filas a mostrar.
typedef TxListArgs = ({int year, int month, int limit});

final transactionListProvider = StreamProvider.autoDispose
    .family<List<TransactionsTableData>, TxListArgs>((ref, args) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.transactionsDao.watchByMonth(
    groupId: groupId,
    year: args.year,
    month: args.month,
    limit: args.limit,
  );
});

/// Total de transacciones en el mes (para saber si hay más páginas).
final transactionCountProvider = FutureProvider.autoDispose
    .family<int, ({int year, int month})>((ref, args) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.transactionsDao.countByMonth(
    groupId: groupId,
    year: args.year,
    month: args.month,
  );
});

// ── Notifier de operaciones CRUD ─────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  TransactionNotifier(this._db, this._groupId, this._sync, this._ref)
      : super(const AsyncData(null));

  final AppDatabase _db;
  final String _groupId;
  final SyncService _sync;
  final Ref _ref;

  Future<bool> save({
    String? existingId,
    required String type,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? categoryId,
    String? description,
    double? amountUsdEquivalent,
    String? accountId,
  }) async {
    state = const AsyncLoading();
    try {
      final userId = supabase.currentUserId;
      final id = existingId ?? const Uuid().v4();

      // Garantizar el equivalente en USD (nunca null): un balance no debe
      // sumar montos en VES como si fueran dólares.
      var usdEquiv = amountUsdEquivalent;
      if (usdEquiv == null) {
        final rates = _ref.read(vesRatesProvider).valueOrNull;
        if (currencyCode == 'USD') {
          usdEquiv = amount;
        } else if (currencyCode == 'EUR') {
          // EUR→USD con la tasa forex real (usdPerEur = EUR/USD del BCE)
          final usdPerEur = rates?.usdPerEur ?? 0;
          if (usdPerEur > 0) usdEquiv = amount * usdPerEur;
        } else if (currencyCode == 'MXN') {
          // MXN→USD dividiendo por la tasa MXN por dólar.
          final r = rates?.usdMxn ?? 0;
          if (r > 0) usdEquiv = amount / r;
        } else if (currencyCode == 'ARS') {
          // ARS→USD: por defecto se usa el blue; si no hay, el oficial.
          final blue = rates?.usdArsBlue ?? 0;
          final r = blue > 0 ? blue : (rates?.usdArsOficial ?? 0);
          if (r > 0) usdEquiv = amount / r;
        } else {
          // VES (u otra moneda cotizada en Bs.) → USD con la tasa paralela
          final rate = rates?.parallel ?? 0;
          if (rate > 0) usdEquiv = amount / rate;
        }
      }

      await _db.transactionsDao.upsertTransaction(
        TransactionsTableCompanion(
          id: Value(id),
          groupId: Value(_groupId),
          userId: Value(userId),
          type: Value(type),
          amount: Value(amount),
          currencyCode: Value(currencyCode),
          date: Value(date),
          categoryId: Value(categoryId),
          description: Value(description),
          amountUsdEquivalent: Value(usdEquiv),
          accountId: Value(accountId),
          isSynced: const Value(false),
        ),
      );
      state = const AsyncData(null);
      _sync.syncPendingTransactions();

      // Verificar presupuesto solo para gastos con categoría asignada
      if (type == 'expense' && categoryId != null) {
        _checkBudget(categoryId);
      }
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      // Si es una transferencia, borrar también el lado vinculado
      final tx = await _db.transactionsDao.getById(id);
      final linkedId = tx?.type == 'transfer' ? tx?.linkedTxId : null;

      // Borrar remotamente (best-effort; errores no critican el flujo)
      try {
        await supabase.from('transactions').delete().eq('id', id);
        if (linkedId != null) {
          await supabase.from('transactions').delete().eq('id', linkedId);
        }
      } catch (_) {}

      // Borrar localmente
      await _db.transactionsDao.deleteTransaction(id);
      if (linkedId != null) {
        await _db.transactionsDao.deleteTransaction(linkedId);
      }

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── Verificación de presupuesto ───────────────────────────────────────────

  Future<void> _checkBudget(String categoryId) async {
    try {
      final limit = await _db.budgetsDao.getLimitForCategory(
        groupId: _groupId,
        categoryId: categoryId,
      );
      if (limit == null || limit <= 0) return;

      final now = DateTime.now();
      final expenses = await _db.transactionsDao.getExpenseByCategory(
        groupId: _groupId,
        year: now.year,
        month: now.month,
      );
      final spent = expenses[categoryId] ?? 0;

      BudgetAlertLevel? level;
      if (spent >= limit) {
        level = BudgetAlertLevel.over;
      } else if (spent >= limit * 0.8) {
        level = BudgetAlertLevel.warning;
      }
      if (level == null) return;

      final alert = BudgetAlert(
        categoryId: categoryId,
        categoryName: _catName(categoryId),
        spent: spent,
        limit: limit,
        level: level,
      );

      // Publica en el provider para que AdaptiveScaffold muestre el SnackBar
      _ref.read(budgetAlertProvider.notifier).state = alert;

      // Notificación del SO en móvil (best-effort)
      NotificationService.instance.showBudgetAlert(alert);
      // Push FCM a los otros dispositivos del grupo (best-effort)
      FcmService.instance.sendGroupPush(
        groupId: _groupId,
        title: alert.isOver
            ? 'Presupuesto superado'
            : 'Alerta de presupuesto',
        body: alert.message,
        data: {'category_id': alert.categoryId},
      );
    } catch (_) {
      // No-crítico: si falla la verificación no interrumpimos el flujo
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider.autoDispose<TransactionNotifier, AsyncValue<void>>(
        (ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  final sync = ref.watch(syncServiceProvider);
  return TransactionNotifier(db, groupId, sync, ref);
});
