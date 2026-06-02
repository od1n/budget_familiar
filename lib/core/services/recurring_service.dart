import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import 'supabase_service.dart';

final _log = Logger();
const _uuid = Uuid();

/// Procesa las plantillas de transacciones recurrentes vencidas,
/// generando una transacción real por cada ocurrencia que haya pasado
/// desde la última vez que se ejecutó el servicio.
///
/// Diseño deliberado: genera TODAS las ocurrencias pendientes, no solo la
/// más reciente, para que el historial del presupuesto sea exacto aunque
/// la app no se haya abierto durante días/semanas.
class RecurringService {
  RecurringService(this._db);
  final AppDatabase _db;

  // ── Punto de entrada principal ────────────────────────────────────────────

  /// Genera todas las transacciones vencidas del grupo y actualiza las
  /// fechas de próxima ejecución. Devuelve el número de transacciones creadas.
  Future<int> processOverdue(String groupId) async {
    if (groupId.isEmpty) return 0;

    String? userId;
    try {
      userId = supabase.currentUserId;
    } catch (_) {
      // Sin sesión activa — no procesamos
      return 0;
    }

    int created = 0;

    try {
      final overdue = await _db.recurringTransactionsDao.getOverdue(groupId);
      if (overdue.isEmpty) return 0;

      _log.i('RecurringService: ${overdue.length} plantillas vencidas');

      final now = DateTime.now();

      for (final template in overdue) {
        try {
          created += await _processTemplate(template, userId, now);
        } catch (e) {
          _log.w('RecurringService: error procesando ${template.id}: $e');
        }
      }

      _log.i('RecurringService: $created transacciones generadas');
    } catch (e) {
      _log.w('RecurringService: error en processOverdue: $e');
    }

    return created;
  }

  // ── Procesamiento de una plantilla ────────────────────────────────────────

  Future<int> _processTemplate(
    RecurringTransactionsTableData template,
    String userId,
    DateTime now,
  ) async {
    int created = 0;
    DateTime dueDate = template.nextDueDate;

    // Genera una transacción por cada ocurrencia vencida.
    // Límite de seguridad: máximo 365 ocurrencias para evitar bucles infinitos
    // si la plantilla lleva años sin procesarse.
    int safety = 0;
    while (!dueDate.isAfter(now) && safety < 365) {
      await _db.transactionsDao.insertTransaction(
        _buildCompanion(template, userId, dueDate),
      );
      created++;
      safety++;
      dueDate = _advanceDate(dueDate, template.frequency, template.dayOfMonth);
    }

    // Actualiza la próxima fecha de vencimiento en la plantilla.
    await _db.recurringTransactionsDao.updateNextDue(template.id, dueDate);

    return created;
  }

  // ── Construcción de companion ─────────────────────────────────────────────

  TransactionsTableCompanion _buildCompanion(
    RecurringTransactionsTableData t,
    String userId,
    DateTime date,
  ) {
    final now = DateTime.now();
    return TransactionsTableCompanion(
      id: Value(_uuid.v4()),
      groupId: Value(t.groupId),
      userId: Value(userId),
      categoryId: Value(t.categoryId),
      amount: Value(t.amount),
      currencyCode: Value(t.currencyCode),
      type: Value(t.type),
      date: Value(date),
      description: Value(t.description),
      isSynced: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  // ── Cálculo de próxima fecha ──────────────────────────────────────────────

  /// Avanza [current] según [frequency], respetando [dayOfMonth] para frecuencias
  /// mensuales/anuales (p. ej. alquiler siempre el día 1, nómina siempre el 15).
  static DateTime advanceDate(
    DateTime current,
    String frequency,
    int? dayOfMonth,
  ) =>
      _advanceDate(current, frequency, dayOfMonth);

  static DateTime _advanceDate(
    DateTime current,
    String frequency,
    int? dayOfMonth,
  ) {
    switch (frequency) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'biweekly':
        return current.add(const Duration(days: 14));
      case 'monthly':
        final next = DateTime(current.year, current.month + 1, 1);
        if (dayOfMonth != null) {
          // Clamp al último día del mes (p. ej. día 31 en febrero → 28/29).
          final lastDay = DateTime(next.year, next.month + 1, 0).day;
          return DateTime(next.year, next.month, dayOfMonth.clamp(1, lastDay));
        }
        // Sin dayOfMonth: misma lógica que DateTime +1 mes, preservando el día.
        final maxDay = DateTime(current.year, current.month + 2, 0).day;
        return DateTime(
          current.year,
          current.month + 1,
          current.day.clamp(1, maxDay),
        );
      case 'yearly':
        final nextYear = current.year + 1;
        // Manejo de año bisiesto: 29-feb → 28-feb en año no bisiesto.
        final maxDay = DateTime(nextYear, current.month + 1, 0).day;
        return DateTime(
          nextYear,
          current.month,
          current.day.clamp(1, maxDay),
        );
      default:
        _log.w('RecurringService: frecuencia desconocida "$frequency"; +30d');
        return current.add(const Duration(days: 30));
    }
  }
}

final recurringServiceProvider = Provider<RecurringService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringService(db);
});
