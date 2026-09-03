import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/local/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/premium_gate.dart';
import '../../providers/investments_provider.dart';

// ── Localización de tipos ────────────────────────────────────────────────────

Map<String, String> _typeLabels(BuildContext context) => {
  'fixed_term':   S.of(context).investmentTypeFixedTerm,
  'fund':         S.of(context).investmentTypeFund,
  'stock':        S.of(context).investmentTypeStock,
  'crypto':       S.of(context).investmentTypeCrypto,
  'real_estate':  S.of(context).investmentTypeRealEstate,
  'other':        S.of(context).investmentTypeOther,
};

const _typeIcons = {
  'fixed_term':   Icons.account_balance_outlined,
  'fund':         Icons.show_chart_outlined,
  'stock':        'stock' == 'stock' ? Icons.candlestick_chart_outlined : Icons.bar_chart,
  'crypto':       Icons.currency_bitcoin_outlined,
  'real_estate':  Icons.home_work_outlined,
  'other':        Icons.attach_money_outlined,
};

IconData _iconFor(String type) =>
    _typeIcons[type] ?? Icons.attach_money_outlined;

final _fmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('+0.0;-0.0');
final _dateFmt = DateFormat('dd/MM/yyyy');

// ── Página ────────────────────────────────────────────────────────────────────

class InvestmentsPage extends ConsumerWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumGate(
      featureLabel: S.of(context).investmentsPageTitle,
      requiredLevel: PlanLevel.family,
      mode: PremiumGateMode.overlay,
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).investmentsPageTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context, ref, null),
          tooltip: S.of(context).newInvestmentTooltip,
          child: const Icon(Icons.add),
        ),
        body: const _InvestmentsBody(),
      ),
    );
  }

  static void _openForm(
    BuildContext context,
    WidgetRef ref,
    InvestmentsTableData? investment,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _InvestmentForm(investment: investment),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _InvestmentsBody extends ConsumerWidget {
  const _InvestmentsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);
    final totals = ref.watch(investmentTotalsProvider);

    return investmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(S.of(context).errorGenericDetail(e.toString()))),
      data: (investments) {
        if (investments.isEmpty) {
          return _EmptyState(
            onAdd: () => InvestmentsPage._openForm(
                context, ref, null),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SummaryCard(totals: totals),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: investments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _InvestmentCard(
                  investment: investments[i],
                  onEdit: () => InvestmentsPage._openForm(
                      context, ref, investments[i]),
                  onDelete: () => _confirmDelete(
                      context, ref, investments[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InvestmentsTableData inv,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).archiveInvestmentTitle),
        content: Text(S.of(context).archiveInvestmentConfirm(inv.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).archiveButton,
                style: const TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(investmentsNotifierProvider.notifier).archive(inv.id);
    }
  }
}

// ── Tarjeta resumen ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});
  final InvestmentTotals totals;

  @override
  Widget build(BuildContext context) {
    final pnlColor =
        totals.isProfit ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _StatCol(
                  label: S.of(context).investedLabel,
                  value: '\$${_fmt.format(totals.totalInvested)}',
                  color: AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _StatCol(
                  label: S.of(context).currentValueLabel,
                  value: '\$${_fmt.format(totals.totalCurrentValue)}',
                  color: AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _StatCol(
                  label: S.of(context).pnlLabel,
                  value:
                      '${_pctFmt.format(totals.pnlPct)}%',
                  color: pnlColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
}

// ── Tarjeta de inversión ──────────────────────────────────────────────────────

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({
    required this.investment,
    required this.onEdit,
    required this.onDelete,
  });
  final InvestmentsTableData investment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    final current = inv.currentValue ?? inv.initialAmount;
    final pnl = current - inv.initialAmount;
    final pnlPct = inv.initialAmount == 0
        ? 0.0
        : (pnl / inv.initialAmount) * 100;
    final isProfit = pnl >= 0;
    final pnlColor = isProfit ? AppColors.income : AppColors.expense;
    final currency = inv.currencyCode;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Ícono de tipo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(inv.type),
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      [
                        _typeLabels(context)[inv.type] ?? inv.type,
                        if (inv.institution != null &&
                            inv.institution!.isNotEmpty)
                          inv.institution!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (inv.maturityDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        S.of(context).maturityLabel(_dateFmt.format(inv.maturityDate!)),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Valores
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${_fmt.format(current)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_pctFmt.format(pnlPct)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pnlColor,
                    ),
                  ),
                ],
              ),
              // Menú
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
                  if (v == 'archive') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            Icon(Icons.trending_up_outlined,
                size: 64,
                color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).investmentsEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).investmentsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).addInvestmentButton),
            ),
          ],
        ),
      );
}

// ── Formulario ────────────────────────────────────────────────────────────────

class _InvestmentForm extends ConsumerStatefulWidget {
  const _InvestmentForm({this.investment});
  final InvestmentsTableData? investment;

  @override
  ConsumerState<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends ConsumerState<_InvestmentForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _initialCtrl;
  late TextEditingController _currentCtrl;
  late TextEditingController _institutionCtrl;
  late TextEditingController _notesCtrl;
  late String _type;
  late String _currency;
  DateTime? _startDate;
  DateTime? _maturityDate;

  bool _saving = false;

  static const _currencies = ['USD', 'VES', 'EUR', 'USDT'];
  static const _types = [
    'fixed_term', 'fund', 'stock', 'crypto', 'real_estate', 'other'
  ];

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;
    _nameCtrl        = TextEditingController(text: inv?.name ?? '');
    _initialCtrl     = TextEditingController(
        text: inv != null ? inv.initialAmount.toStringAsFixed(2) : '');
    _currentCtrl     = TextEditingController(
        text: inv?.currentValue?.toStringAsFixed(2) ?? '');
    _institutionCtrl = TextEditingController(text: inv?.institution ?? '');
    _notesCtrl       = TextEditingController(text: inv?.notes ?? '');
    _type            = inv?.type ?? 'other';
    _currency        = inv?.currencyCode ?? 'USD';
    _startDate       = inv?.startDate;
    _maturityDate    = inv?.maturityDate;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _initialCtrl, _currentCtrl,
        _institutionCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.investment != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? S.of(context).editInvestmentTitle : S.of(context).newInvestmentTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nombre
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: '${S.of(context).investmentNameLabel} *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.of(context).requiredField : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Tipo
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: S.of(context).investmentTypeLabel),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_iconFor(t), size: 18,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(_typeLabels(context)[t] ?? t),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'other'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Moneda + monto inicial
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: InputDecoration(labelText: S.of(context).currencyFieldLabel),
                      items: _currencies
                          .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _currency = v ?? 'USD'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _initialCtrl,
                      decoration:
                          InputDecoration(labelText: '${S.of(context).initialAmountLabel} *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return S.of(context).requiredField;
                        if (double.tryParse(v) == null) return S.of(context).invalidNumber;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Valor actual
              TextFormField(
                controller: _currentCtrl,
                decoration: InputDecoration(
                  labelText: S.of(context).currentValueFormLabel,
                  helperText: S.of(context).currentValueHelper,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return S.of(context).invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Institución
              TextFormField(
                controller: _institutionCtrl,
                decoration: InputDecoration(
                    labelText: S.of(context).institutionLabel),
              ),
              const SizedBox(height: AppSpacing.md),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: S.of(context).startDateLabel,
                      value: _startDate,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateField(
                      label: S.of(context).maturityDateLabel,
                      value: _maturityDate,
                      onChanged: (d) => setState(() => _maturityDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Notas
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(labelText: S.of(context).notesLabel),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botón guardar
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? S.of(context).saveChangesButton : S.of(context).addInvestmentButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final notifier =
        ref.read(investmentsNotifierProvider.notifier);
    final initialAmount = double.parse(_initialCtrl.text);
    final currentValue = _currentCtrl.text.isEmpty
        ? null
        : double.parse(_currentCtrl.text);

    if (widget.investment == null) {
      await notifier.add(
        name: _nameCtrl.text,
        type: _type,
        initialAmount: initialAmount,
        currentValue: currentValue,
        currencyCode: _currency,
        startDate: _startDate,
        maturityDate: _maturityDate,
        institution: _institutionCtrl.text.trim().isEmpty
            ? null
            : _institutionCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
    } else {
      await notifier.update(
        id: widget.investment!.id,
        name: _nameCtrl.text,
        type: _type,
        initialAmount: initialAmount,
        currentValue: currentValue,
        currencyCode: _currency,
        startDate: _startDate,
        maturityDate: _maturityDate,
        institution: _institutionCtrl.text.trim().isEmpty
            ? null
            : _institutionCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }
}

// ── Selector de fecha ─────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(
          value != null ? _dateFmt.format(value!) : 'Seleccionar',
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
