import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/local/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/savings_provider.dart';

// ── Cálculo de meta ajustada ──────────────────────────────────────────────────

/// Proyecta el monto objetivo al futuro aplicando inflación compuesta mensual.
/// [monthlyRatePct] = 4.5 → 4.5 % mensual (típico Venezuela).
/// Devuelve [target] sin cambios si no hay fecha o ya venció.
double _calcAdjustedTarget(
  double target,
  double monthlyRatePct,
  DateTime? deadline,
) {
  if (deadline == null) return target;
  final now = DateTime.now();
  if (!deadline.isAfter(now)) return target;
  final months = (deadline.difference(now).inDays / 30.0).ceil();
  if (months <= 0) return target;
  return target * pow(1 + monthlyRatePct / 100, months);
}

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).savingsPageTitle)),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.of(context).errorGenericDetail(e.toString()))),
        data: (goals) => goals.isEmpty
            ? _EmptyState(onNew: () => _openForm(context, ref))
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  ...goals.map(
                    (g) => _GoalCard(
                      goal: g,
                      onDelete: () => ref
                          .read(savingsGoalNotifierProvider.notifier)
                          .delete(g.id),
                      onAddAmount: () => _addAmount(context, ref, g),
                      onEdit: () => _editGoal(context, ref, g),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _openForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(S.of(context).newGoalButton),
                  ),
                  const SizedBox(height: AppSpacing.x5l),
                ],
              ),
      ),
    );
  }

  // ── Formulario nueva meta ─────────────────────────────────────────────────
  // Usa showDialog (NO showModalBottomSheet) para evitar el bug
  // '!semantics.parentDataDirty' en Windows Desktop.
  // Usa GestureDetector para el selector de moneda (NO DropdownButtonFormField).

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _NewGoalDialog(
        nameCtrl: nameCtrl,
        targetCtrl: targetCtrl,
        onSave: (name, target, currency) async {
          Navigator.pop(dialogContext);
          await ref.read(savingsGoalNotifierProvider.notifier).create(
                name: name,
                targetAmount: target,
                currencyCode: currency,
              );
        },
      ),
    );
  }

  // ── Editar meta existente ────────────────────────────────────────────────

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalsTableData goal,
  ) async {
    final nameCtrl = TextEditingController(text: goal.name);
    final targetCtrl =
        TextEditingController(text: goal.targetAmount.toStringAsFixed(2));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditGoalDialog(
        nameCtrl: nameCtrl,
        targetCtrl: targetCtrl,
        initialCurrency: goal.currencyCode,
        initialDate: goal.targetDate,
        initialInflationRate: goal.inflationRateMonthly,
        onSave: (name, target, currency, date, inflationRate) async {
          Navigator.pop(dialogContext);
          await ref.read(savingsGoalNotifierProvider.notifier).update(
                id: goal.id,
                name: name,
                targetAmount: target,
                currencyCode: currency,
                targetDate: date,
              );
          await ref.read(savingsGoalNotifierProvider.notifier).updateInflationRate(
                id: goal.id,
                monthlyRate: inflationRate,
              );
        },
      ),
    );
  }

  // ── Agregar monto a meta existente ────────────────────────────────────────

  Future<void> _addAmount(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalsTableData goal,
  ) async {
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).addSavingsTitle(goal.name)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: S.of(context).addSavingsAmountLabel(goal.currencyCode),
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, double.tryParse(ctrl.text)),
            child: Text(S.of(context).addButton),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await ref.read(savingsGoalNotifierProvider.notifier).addAmount(
            id: goal.id,
            currentAmount: goal.currentAmount,
            addValue: result,
            targetAmount: goal.targetAmount,
          );
    }
  }
}

// ── Dialog nueva meta (stateful para selector de moneda) ─────────────────────

class _NewGoalDialog extends StatefulWidget {
  const _NewGoalDialog({
    required this.nameCtrl,
    required this.targetCtrl,
    required this.onSave,
  });
  final TextEditingController nameCtrl;
  final TextEditingController targetCtrl;
  final void Function(String name, double target, String currency) onSave;

  @override
  State<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends State<_NewGoalDialog> {
  String _currency = 'USD';
  String? _nameError;
  String? _amountError;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).newGoalDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: S.of(context).goalNameLabel,
                hintText: S.of(context).goalNameHint,
                errorText: _nameError,
              ),
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.targetCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).targetAmountLabel,
                      prefixText: '\$ ',
                      errorText: _amountError,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() => _amountError = null),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Selector de moneda con GestureDetector — evita el bug de
                // DropdownButtonFormField en Windows Desktop.
                Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _CurrencyToggle(
                      value: _currency,
                      onChanged: (v) => setState(() => _currency = v),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(S.of(context).createButton),
        ),
      ],
    );
  }

  void _submit() {
    final name = widget.nameCtrl.text.trim();
    final target = double.tryParse(widget.targetCtrl.text);
    bool valid = true;

    if (name.isEmpty) {
      setState(() => _nameError = S.of(context).goalNameValidation);
      valid = false;
    }
    if (target == null || target <= 0) {
      setState(() => _amountError = S.of(context).goalAmountValidation);
      valid = false;
    }
    if (!valid) return;
    widget.onSave(name, target!, _currency);
  }
}

// ── Selector moneda (sin DropdownButtonFormField) ─────────────────────────────

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['USD', 'VES'].map((cur) {
        final active = cur == value;
        return GestureDetector(
          onTap: () => onChanged(cur),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              cur,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Tarjeta de meta ───────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onDelete,
    required this.onAddAmount,
    required this.onEdit,
  });
  final SavingsGoalsTableData goal;
  final VoidCallback onDelete;
  final VoidCallback onAddAmount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    final color = progress >= 1.0 ? AppColors.income : AppColors.savings;
    final fmt = NumberFormat('#,##0.00', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  tooltip: S.of(context).editGoal,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: S.of(context).deleteButton,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currencyCode} ${fmt.format(goal.currentAmount)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      S.of(context).savingsOfTarget('${goal.currencyCode} ${fmt.format(goal.targetAmount)}'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (goal.inflationRateMonthly != null &&
                        goal.targetDate != null)
                      Text(
                        S.of(context).savingsAdjusted('${goal.currencyCode} ${fmt.format(_calcAdjustedTarget(goal.targetAmount, goal.inflationRateMonthly!, goal.targetDate))}'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).percentCompleted(pct),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    if (goal.targetDate != null)
                      Text(
                        S.of(context).dateColonLabel(DateFormat('d MMM yyyy', 'es').format(goal.targetDate!)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
                if (progress < 1.0)
                  TextButton.icon(
                    onPressed: onAddAmount,
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(S.of(context).addButton),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.income,
                    size: 18,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog editar meta ────────────────────────────────────────────────────────

class _EditGoalDialog extends StatefulWidget {
  const _EditGoalDialog({
    required this.nameCtrl,
    required this.targetCtrl,
    required this.initialCurrency,
    required this.onSave,
    this.initialDate,
    this.initialInflationRate,
  });
  final TextEditingController nameCtrl;
  final TextEditingController targetCtrl;
  final String initialCurrency;
  final DateTime? initialDate;
  final double? initialInflationRate;
  final void Function(
    String name,
    double target,
    String currency,
    DateTime? date,
    double? inflationRate,
  ) onSave;

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late String _currency;
  DateTime? _targetDate;
  String? _nameError;
  String? _amountError;

  bool _inflationEnabled = false;
  late TextEditingController _inflationRateCtrl;

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency;
    _targetDate = widget.initialDate;
    _inflationEnabled = widget.initialInflationRate != null;
    _inflationRateCtrl = TextEditingController(
      text: widget.initialInflationRate?.toStringAsFixed(1) ?? '4.5',
    );
  }

  @override
  void dispose() {
    _inflationRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).editGoalTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: S.of(context).nameLabel,
                errorText: _nameError,
              ),
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.targetCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).targetAmountLabel,
                      prefixText: '\$ ',
                      errorText: _amountError,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() => _amountError = null),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _CurrencyToggle(
                      value: _currency,
                      onChanged: (v) => setState(() => _currency = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Fecha objetivo ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: S.of(context).targetDateLabel,
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _targetDate == null
                      ? S.of(context).noDateSet
                      : DateFormat('d MMM yyyy', 'es').format(_targetDate!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (_targetDate != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _targetDate = null),
                  child: Text(S.of(context).removeDateButton),
                ),
              ),
            ],

            // ── Ajuste por inflación ────────────────────────────────────────
            const Divider(height: AppSpacing.x2l),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                S.of(context).adjustForInflation,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                S.of(context).inflationSubtitle,
                style: const TextStyle(fontSize: 11),
              ),
              value: _inflationEnabled,
              onChanged: (v) => setState(() => _inflationEnabled = v),
            ),
            if (_inflationEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _inflationRateCtrl,
                decoration: InputDecoration(
                  labelText: S.of(context).inflationRateLabel,
                  helperText: S.of(context).inflationRateHelper,
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              if (_targetDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Builder(
                  builder: (ctx) {
                    final rate =
                        double.tryParse(_inflationRateCtrl.text) ?? 0;
                    final target =
                        double.tryParse(widget.targetCtrl.text) ?? 0;
                    final adjusted =
                        _calcAdjustedTarget(target, rate, _targetDate);
                    final fmt = NumberFormat('#,##0.00', 'es');
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            S.of(context).adjustedGoalLabel(_currency, fmt.format(adjusted)),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(S.of(context).saveButton),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    final name = widget.nameCtrl.text.trim();
    final target = double.tryParse(widget.targetCtrl.text);
    bool valid = true;
    if (name.isEmpty) {
      setState(() => _nameError = S.of(context).goalNameValidation);
      valid = false;
    }
    if (target == null || target <= 0) {
      setState(() => _amountError = S.of(context).goalAmountValidation);
      valid = false;
    }
    if (!valid) return;
    final inflationRate = _inflationEnabled
        ? double.tryParse(_inflationRateCtrl.text)
        : null;
    widget.onSave(name, target!, _currency, _targetDate, inflationRate);
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.savings_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).savingsEmptyTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              S.of(context).savingsEmptySubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).newGoalButton),
            ),
          ],
        ),
      );
}
