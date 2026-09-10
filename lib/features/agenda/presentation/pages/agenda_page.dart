import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/local/app_database.dart';
import '../../../../router/app_router.dart';
import '../../../family/providers/family_provider.dart';

// ── Proveedor ─────────────────────────────────────────────────────────────────

/// Pagos e ingresos programados (recurrentes activos) del grupo, ordenados por
/// próxima fecha de vencimiento. Reutiliza el sistema de transacciones
/// recurrentes existente; no requiere tablas nuevas.
final agendaProvider =
    StreamProvider.autoDispose<List<RecurringTransactionsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  if (groupId.isEmpty) {
    return const Stream<List<RecurringTransactionsTableData>>.empty();
  }
  return db.recurringTransactionsDao.watchActive(groupId);
});

// ── Utilidades de fecha ───────────────────────────────────────────────────────

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysUntil(DateTime due) =>
    _dayOnly(due).difference(_dayOnly(DateTime.now())).inDays;

String _whenLabel(DateTime due) {
  final d = _daysUntil(due);
  if (d < 0) return 'Vencido';
  if (d == 0) return 'Hoy';
  if (d == 1) return 'Mañana';
  return 'En $d días';
}

Color _whenColor(DateTime due) {
  final d = _daysUntil(due);
  if (d < 0) return AppColors.expense;
  if (d <= 2) return AppColors.warning;
  return AppColors.textSecondary;
}

/// Programa un recordatorio local un día antes del vencimiento (a las 9:00).
/// Idempotente: usa un ID estable por plantilla, así reprogramar reemplaza.
void _scheduleReminder(RecurringTransactionsTableData t) {
  final due = t.nextDueDate;
  final when = DateTime(due.year, due.month, due.day, 9)
      .subtract(const Duration(days: 1));
  final id = t.id.hashCode & 0x7FFFFFFF;
  final signo = t.type == 'income' ? 'Cobro' : 'Pago';
  final desc = (t.description == null || t.description!.isEmpty)
      ? (t.type == 'income' ? 'ingreso programado' : 'pago programado')
      : t.description!;
  NotificationService.instance.scheduleReminder(
    id: id,
    title: 'Recordatorio: $signo mañana',
    body: '$desc — ${t.amount.toStringAsFixed(2)} ${t.currencyCode}',
    when: when,
  );
}

void _scheduleAll(List<RecurringTransactionsTableData> items) {
  for (final t in items) {
    if (_daysUntil(t.nextDueDate) >= 0) _scheduleReminder(t);
  }
}

// ── Fila de un pago programado ────────────────────────────────────────────────

class _AgendaTile extends StatelessWidget {
  const _AgendaTile(this.t);
  final RecurringTransactionsTableData t;

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == 'income';
    final fmtDate = DateFormat('d MMM yyyy', 'es');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? AppColors.income : AppColors.expense,
          size: 18,
        ),
      ),
      title: Text(
        (t.description == null || t.description!.isEmpty)
            ? (isIncome ? 'Ingreso programado' : 'Pago programado')
            : t.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${fmtDate.format(t.nextDueDate)} · ${_whenLabel(t.nextDueDate)}',
        style: TextStyle(fontSize: 12, color: _whenColor(t.nextDueDate)),
      ),
      trailing: Text(
        '${t.amount.toStringAsFixed(2)} ${t.currencyCode}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
      ),
    );
  }
}

// ── Pantalla completa de agenda ───────────────────────────────────────────────

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agendaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Próximos pagos')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('No se pudo cargar la agenda.')),
        data: (items) {
          // Programa los recordatorios (idempotente).
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scheduleAll(items));
          if (items.isEmpty) {
            return const _EmptyAgenda();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _AgendaTile(items[i]),
          );
        },
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_outlined,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tienes pagos ni ingresos programados.\n'
              'Créalos desde las transacciones recurrentes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta compacta para el panel ────────────────────────────────────────────

/// Muestra los próximos pagos (máximo 3) y un acceso a la agenda completa.
/// Si no hay nada programado, no ocupa espacio.
class UpcomingPaymentsCard extends ConsumerWidget {
  const UpcomingPaymentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agendaProvider);
    final items = async.valueOrNull;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    final upcoming =
        items.where((t) => _daysUntil(t.nextDueDate) >= 0).take(3).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Próximos pagos',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(AppRoutes.agenda),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            ...upcoming.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      t.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 14,
                      color: t.type == 'income'
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        (t.description == null || t.description!.isEmpty)
                            ? (t.type == 'income'
                                ? 'Ingreso programado'
                                : 'Pago programado')
                            : t.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _whenLabel(t.nextDueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: _whenColor(t.nextDueDate),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
