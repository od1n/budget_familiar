import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/exchange_rate_service.dart';
import '../../../data/local/app_database.dart';
import '../../family/providers/family_provider.dart';
import '../../recurring/providers/recurring_transactions_provider.dart';
import '../services/projection_service.dart';

/// Horizonte de la proyección en meses (3, 6 o 12). Editable desde la pantalla.
final projectionHorizonProvider = StateProvider<int>((_) => 12);

/// Proyección de saldo calculada a partir de:
///  - el saldo actual (neto histórico acumulado en USD),
///  - las plantillas recurrentes activas (agenda),
///  - el promedio de gasto de los últimos 3 meses,
///  - las tasas de cambio para convertir cada moneda a USD.
final projectionProvider =
    FutureProvider.autoDispose<ProjectionResult>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  final horizon = ref.watch(projectionHorizonProvider);
  final rates = ref.watch(vesRatesProvider).valueOrNull;
  // Reactivo: si cambian las plantillas, la proyección se recalcula.
  final templates = ref.watch(recurringListProvider).valueOrNull ?? const [];

  if (groupId.isEmpty) return ProjectionResult.empty;

  final now = DateTime.now();

  // Saldo actual = neto histórico en USD (ingresos - gastos, sin transferencias).
  final allTime = await db.transactionsDao.getSummaryForRange(
    groupId: groupId,
    start: DateTime(2000),
    end: now,
  );

  // Promedio de gasto mensual de los últimos 3 meses.
  final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
  final recent = await db.transactionsDao.getSummaryForRange(
    groupId: groupId,
    start: threeMonthsAgo,
    end: now,
  );
  final avgMonthlyExpense = recent.totalExpense / 3;

  return ProjectionService.compute(
    startingBalanceUsd: allTime.balance,
    templates: templates,
    avgTotalMonthlyExpenseUsd: avgMonthlyExpense,
    horizonMonths: horizon,
    rates: rates,
    now: now,
  );
});
