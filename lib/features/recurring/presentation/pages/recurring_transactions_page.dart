import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../data/local/app_database.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../providers/recurring_transactions_provider.dart';

// ── Helpers de formato ────────────────────────────────────────────────────────

String _fmtMoney(double v) => NumberFormat('#,##0.00', 'es').format(v);
String _fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'es').format(d);

const _kFrequencies = [
  ('daily', 'Diaria'),
  ('weekly', 'Semanal'),
  ('biweekly', 'Quincenal'),
  ('monthly', 'Mensual'),
  ('yearly', 'Anual'),
];

String _freqLabel(BuildContext context, String freq) => switch (freq) {
      'daily' => S.of(context).freqDaily,
      'weekly' => S.of(context).freqWeekly,
      'biweekly' => S.of(context).freqBiweekly,
      'monthly' => S.of(context).freqMonthly,
      'yearly' => S.of(context).freqYearly,
      _ => freq,
    };

const _kSystemCategories = <(String, String, String)>[
  ('sys_food', 'Alimentación', 'restaurant'),
  ('sys_transport', 'Transporte', 'directions_car'),
  ('sys_services', 'Servicios', 'bolt'),
  ('sys_health', 'Salud', 'local_hospital'),
  ('sys_education', 'Educación', 'school'),
  ('sys_entertainment', 'Entretenimiento', 'movie'),
  ('sys_clothing', 'Ropa', 'checkroom'),
  ('sys_home', 'Hogar', 'home'),
  ('sys_debt', 'Deudas', 'credit_card'),
  ('sys_other', 'Otros gastos', 'more_horiz'),
  ('sys_income_salary', 'Salario', 'work'),
  ('sys_income_freelance', 'Freelance', 'laptop'),
  ('sys_income_investment', 'Inversiones', 'trending_up'),
  ('sys_income_other', 'Otros ingresos', 'attach_money'),
];

// ── Página principal ──────────────────────────────────────────────────────────

class RecurringTransactionsPage extends ConsumerWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(recurringListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).recurringPageTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        tooltip: S.of(context).newTemplate,
        child: const Icon(Icons.add),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.of(context).errorGenericDetail(e.toString()))),
        data: (templates) => templates.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context, ref, null))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: templates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _RecurringTile(
                  template: templates[i],
                  onEdit: () => _openForm(context, ref, templates[i]),
                  onDelete: () =>
                      _confirmDelete(context, ref, templates[i]),
                ),
              ),
      ),
    );
  }

  void _openForm(
    BuildContext context,
    WidgetRef ref,
    RecurringTransactionsTableData? existing,
  ) {
    final customCatsAsync = ref.read(customCategoriesProvider);
    final customCats = customCatsAsync.valueOrNull ?? [];

    showDialog<void>(
      context: context,
      builder: (_) => _RecurringForm(
        existing: existing,
        customCategories: customCats,
        onSave: (params) async {
          final notifier = ref.read(recurringNotifierProvider.notifier);
          bool ok;
          if (existing == null) {
            ok = await notifier.create(
              amount: params.amount,
              currencyCode: params.currencyCode,
              type: params.type,
              frequency: params.frequency,
              nextDueDate: params.nextDueDate,
              categoryId: params.categoryId,
              description: params.description,
              dayOfMonth: params.dayOfMonth,
            );
          } else {
            ok = await notifier.update(
              id: existing.id,
              amount: params.amount,
              currencyCode: params.currencyCode,
              type: params.type,
              frequency: params.frequency,
              nextDueDate: params.nextDueDate,
              categoryId: params.categoryId,
              description: params.description,
              dayOfMonth: params.dayOfMonth,
            );
          }
          if (ok && context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransactionsTableData template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).deleteTemplateTitle),
        content: Text(
          S.of(context).deleteTemplateWarning(template.description ?? _freqLabel(context, template.frequency)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(context).deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(recurringNotifierProvider.notifier).delete(template.id);
    }
  }
}

// ── Tile de plantilla ─────────────────────────────────────────────────────────

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransactionsTableData template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = template.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final bgColor = isIncome ? AppColors.incomeLight : AppColors.expenseLight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Ícono de tipo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Contenido central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${template.currencyCode} ${_fmtMoney(template.amount)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FreqBadge(freq: template.frequency),
                    ],
                  ),
                  if (template.description != null &&
                      template.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      template.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 13,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        S.of(context).nextDueLabel(_fmtDate(template.nextDueDate)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle activo/inactivo
            Switch(
              value: template.isActive,
              onChanged: (val) => ref
                  .read(recurringNotifierProvider.notifier)
                  .toggleActive(template.id, active: val),
              activeThumbColor: AppColors.primary,
            ),

            // Acciones
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: S.of(context).editButton,
              color: AppColors.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: S.of(context).deleteButton,
              color: AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge de frecuencia ───────────────────────────────────────────────────────

class _FreqBadge extends StatelessWidget {
  const _FreqBadge({required this.freq});
  final String freq;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          _freqLabel(context, freq),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.lg),
            Text(
              S.of(context).noTemplates,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).noTemplatesSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                  ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).newTemplate),
            ),
          ],
        ),
      );
}

// ── Parámetros del formulario ─────────────────────────────────────────────────

class _FormParams {
  _FormParams({
    required this.amount,
    required this.currencyCode,
    required this.type,
    required this.frequency,
    required this.nextDueDate,
    this.categoryId,
    this.description,
    this.dayOfMonth,
  });

  final double amount;
  final String currencyCode;
  final String type;
  final String frequency;
  final DateTime nextDueDate;
  final String? categoryId;
  final String? description;
  final int? dayOfMonth;
}

// ── Formulario de alta/edición ────────────────────────────────────────────────

class _RecurringForm extends StatefulWidget {
  const _RecurringForm({
    required this.existing,
    required this.customCategories,
    required this.onSave,
  });

  final RecurringTransactionsTableData? existing;
  final List<CategoriesTableData> customCategories;
  final Future<void> Function(_FormParams) onSave;

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();

  String _type = 'expense';
  String _currency = 'USD';
  String _frequency = 'monthly';
  String? _categoryId;
  DateTime _nextDue = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toString();
      _descCtrl.text = e.description ?? '';
      _type = e.type;
      _currency = e.currencyCode;
      _frequency = e.frequency;
      _categoryId = e.categoryId;
      _nextDue = e.nextDueDate;
      if (e.dayOfMonth != null) {
        _dayCtrl.text = e.dayOfMonth.toString();
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError(S.of(context).enterValidAmount);
      return;
    }

    int? dayOfMonth;
    if (_frequency == 'monthly' && _dayCtrl.text.isNotEmpty) {
      dayOfMonth = int.tryParse(_dayCtrl.text);
      if (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 28) {
        _showError(S.of(context).dayOfMonthRange);
        return;
      }
    }

    setState(() => _saving = true);

    await widget.onSave(
      _FormParams(
        amount: amount,
        currencyCode: _currency,
        type: _type,
        frequency: _frequency,
        nextDueDate: _nextDue,
        categoryId: _categoryId,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dayOfMonth: dayOfMonth,
      ),
    );

    if (mounted) setState(() => _saving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? S.of(context).editTemplate : S.of(context).newTemplate),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo: Ingreso / Gasto
              _SectionLabel(S.of(context).fieldType),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'income',
                    label: Text(S.of(context).incomeTypeButton),
                    icon: Icon(Icons.arrow_downward, size: 16),
                  ),
                  ButtonSegment(
                    value: 'expense',
                    label: Text(S.of(context).expenseTypeButton),
                    icon: Icon(Icons.arrow_upward, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
                style: ButtonStyle(
                  iconColor: WidgetStateProperty.resolveWith(
                    (states) => _type == 'income'
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Monto + moneda
              _SectionLabel(S.of(context).amountLabel),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Selector de moneda
                  GestureDetector(
                    onTap: _pickCurrency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currency,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.00',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Frecuencia
              _SectionLabel(S.of(context).frequencyLabel),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickFrequency,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_freqLabel(context, _frequency)),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              ),
              // Campo día del mes (solo si frecuencia = monthly)
              if (_frequency == 'monthly') ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _dayCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: S.of(context).dayOfMonthLabel,
                    hintText: S.of(context).dayOfMonthHint,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Próxima fecha
              _SectionLabel(S.of(context).nextDateLabel),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_fmtDate(_nextDue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categoría
              _SectionLabel(S.of(context).categoryOptionalLabel),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => _pickCategory(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _categoryId != null
                            ? _catName(context, _categoryId!)
                            : S.of(context).noCategoryLabel,
                        style: TextStyle(
                          color: _categoryId != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Descripción
              TextField(
                controller: _descCtrl,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: S.of(context).descriptionOptionalLabel,
                  hintText: S.of(context).descriptionHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancelButton),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickCurrency() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(context).currencyFieldLabel),
        children: ['USD', 'VES', 'EUR']
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(c),
                child: Text(c),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Future<void> _pickFrequency() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(context).frequencyLabel),
        children: _kFrequencies
            .map(
              (f) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(f.$1),
                child: Row(
                  children: [
                    Icon(
                      _freqIcon(f.$1),
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_freqLabel(context, f.$1)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null) setState(() => _frequency = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _nextDue = picked);
  }

  Future<void> _pickCategory(BuildContext context) async {
    final sysItems = _kSystemCategories.where((c) {
      if (_type == 'income') return c.$1.startsWith('sys_income');
      return !c.$1.startsWith('sys_income');
    }).toList();

    final customItems = widget.customCategories.where((c) {
      if (_type == 'income') return c.type == 'income';
      return c.type == 'expense';
    }).toList();

    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(S.of(context).categoryLabel),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('__none__'),
            child: Row(
              children: [
                const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(S.of(context).noCategoryLabel),
              ],
            ),
          ),
          const Divider(height: 8),
          ...sysItems.map(
            (c) => SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c.$1),
              child: Row(
                children: [
                  Icon(
                    iconFromCode(c.$3),
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(categoryDisplayName(context, c.$1, c.$2)),
                ],
              ),
            ),
          ),
          if (customItems.isNotEmpty) ...[
            const Divider(height: 8),
            ...customItems.map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(c.id),
                child: Row(
                  children: [
                    Icon(
                      iconFromCode(c.iconCode),
                      size: 18,
                      color: colorFromHex(c.colorHex),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(c.name),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (picked == '__none__') {
      setState(() => _categoryId = null);
    } else if (picked != null) {
      setState(() => _categoryId = picked);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _catName(BuildContext context, String id) {
    final custom = widget.customCategories.where((c) => c.id == id).firstOrNull;
    return categoryDisplayName(context, id, custom?.name ?? id);
  }

  IconData _freqIcon(String freq) => switch (freq) {
        'daily' => Icons.today,
        'weekly' => Icons.view_week,
        'biweekly' => Icons.date_range,
        'monthly' => Icons.calendar_month,
        'yearly' => Icons.calendar_today,
        _ => Icons.repeat,
      };
}

// ── Etiqueta de sección ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      );
}
