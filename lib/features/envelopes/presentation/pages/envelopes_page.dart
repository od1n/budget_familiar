import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/local/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/premium_gate.dart';
import '../../providers/envelopes_provider.dart';

final _fmt = NumberFormat('#,##0.00', 'es');
final _dateFmt = DateFormat('d MMM', 'es');

class EnvelopesPage extends ConsumerWidget {
  const EnvelopesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumGate(
      featureLabel: 'Sobres virtuales',
      requiredLevel: PlanLevel.family,
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).envelopesPageTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context, ref, null),
          tooltip: S.of(context).newEnvelopeTooltip,
          child: const Icon(Icons.add),
        ),
        body: const _EnvelopesBody(),
      ),
    );
  }

  static void _openForm(BuildContext context, WidgetRef ref,
      VirtualEnvelopesTableData? envelope) {
    showDialog<void>(
      context: context,
      builder: (_) => _EnvelopeForm(envelope: envelope),
    );
  }
}

// ── Cuerpo ────────────────────────────────────────────────────────────────────

class _EnvelopesBody extends ConsumerWidget {
  const _EnvelopesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envsAsync = ref.watch(envelopesProvider);

    return envsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (envs) {
        if (envs.isEmpty) return _EmptyState(
          onAdd: () => EnvelopesPage._openForm(context, ref, null),
        );
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ...envs.map((e) => _EnvelopeCard(
                  envelope: e,
                  onEdit: () => EnvelopesPage._openForm(context, ref, e),
                  onArchive: () => ref
                      .read(envelopesNotifierProvider.notifier)
                      .archive(e.id),
                  onAddSpent: () => _addSpent(context, ref, e),
                )),
            const SizedBox(height: AppSpacing.x5l),
          ],
        );
      },
    );
  }

  Future<void> _addSpent(
      BuildContext context, WidgetRef ref, VirtualEnvelopesTableData env) async {
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).registerSpentTitle(env.name)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: S.of(context).registerSpentAmountLabel(env.currencyCode),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text)),
            child: Text(S.of(context).registerSpentButton),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      ref.read(envelopesNotifierProvider.notifier).addSpent(
            id: env.id,
            currentSpent: env.spentAmount,
            add: result,
          );
    }
  }
}

// ── Tarjeta de sobre ──────────────────────────────────────────────────────────

class _EnvelopeCard extends StatelessWidget {
  const _EnvelopeCard({
    required this.envelope,
    required this.onEdit,
    required this.onArchive,
    required this.onAddSpent,
  });
  final VirtualEnvelopesTableData envelope;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onAddSpent;

  @override
  Widget build(BuildContext context) {
    final env = envelope;
    final remaining = env.allocatedAmount - env.spentAmount;
    final progress = env.allocatedAmount > 0
        ? (env.spentAmount / env.allocatedAmount).clamp(0.0, 1.0)
        : 0.0;
    final isOver = env.spentAmount >= env.allocatedAmount;
    final color = isOver
        ? AppColors.expense
        : progress >= 0.8
            ? AppColors.warning
            : AppColors.income;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.wallet_outlined, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(env.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '${_dateFmt.format(env.periodStart)} — '
                        '${_dateFmt.format(env.periodEnd)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textDisabled),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AppColors.textSecondary),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'edit', child: Text(S.of(ctx).editButton)),
                    PopupMenuItem(
                        value: 'archive',
                        child: Text(S.of(ctx).archiveButton,
                            style: const TextStyle(color: AppColors.expense))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'archive') onArchive();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${env.currencyCode} ${_fmt.format(env.spentAmount)} gastado',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
                Text(
                  'de ${_fmt.format(env.allocatedAmount)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOver
                      ? 'Excedido en ${env.currencyCode} ${_fmt.format(-remaining)}'
                      : S.of(context).envelopeAvailable(env.currencyCode, _fmt.format(remaining)),
                  style: TextStyle(
                      fontSize: 11,
                      color: isOver
                          ? AppColors.expense
                          : AppColors.textSecondary),
                ),
                if (!isOver)
                  TextButton.icon(
                    onPressed: onAddSpent,
                    icon: const Icon(Icons.remove_circle_outline, size: 14),
                    label: Text(S.of(context).spendButton),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulario ────────────────────────────────────────────────────────────────

class _EnvelopeForm extends ConsumerStatefulWidget {
  const _EnvelopeForm({this.envelope});
  final VirtualEnvelopesTableData? envelope;

  @override
  ConsumerState<_EnvelopeForm> createState() => _EnvelopeFormState();
}

class _EnvelopeFormState extends ConsumerState<_EnvelopeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late String _currency;
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;

  static const _currencies = ['USD', 'VES', 'EUR', 'USDT'];

  @override
  void initState() {
    super.initState();
    final e = widget.envelope;
    _nameCtrl   = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.allocatedAmount.toStringAsFixed(2) : '');
    _currency = e?.currencyCode ?? 'USD';
    final now = DateTime.now();
    _start = e?.periodStart ??
        DateTime(now.year, now.month, 1);
    _end   = e?.periodEnd ??
        DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.envelope != null;
    return AlertDialog(
      title: Text(isEdit ? S.of(context).editEnvelopeTitle : S.of(context).newEnvelopeTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    InputDecoration(labelText: '${S.of(context).envelopeNameLabel} *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.of(context).requiredField : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration:
                          InputDecoration(labelText: '${S.of(context).allocatedAmountLabel} *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return S.of(context).requiredField;
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DropdownButton<String>(
                    value: _currency,
                    items: _currencies
                        .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'USD'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Período
              Row(
                children: [
                  Expanded(
                    child: _DatePicker(
                      label: S.of(context).periodStartLabel,
                      value: _start,
                      onChanged: (d) => setState(() => _start = d),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DatePicker(
                      label: S.of(context).periodEndLabel,
                      value: _end,
                      onChanged: (d) => setState(() => _end = d),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? S.of(context).saveButton : S.of(context).createButton),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(envelopesNotifierProvider.notifier).create(
          name: _nameCtrl.text,
          allocatedAmount: double.parse(_amountCtrl.text),
          currencyCode: _currency,
          periodStart: _start,
          periodEnd: _end,
        );
    if (mounted) Navigator.pop(context);
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            DateFormat('d MMM yyyy', 'es').format(value),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wallet_outlined,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(S.of(context).envelopesEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).envelopesEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).createEnvelopeButton),
            ),
          ],
        ),
      );
}
