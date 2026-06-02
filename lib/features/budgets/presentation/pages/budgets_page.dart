import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../data/local/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../family/providers/family_provider.dart';
import '../../providers/budgets_provider.dart';

// ── Provider combinado ────────────────────────────────────────────────────────

/// Stream reactivo de categorías de gasto del grupo activo.
final _expenseCategoriesProvider =
    StreamProvider<List<CategoriesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return db.categoriesDao
      .watchCategoriesForGroup(groupId)
      .map((cats) => cats.where((c) => c.type == 'expense').toList());
});

// ── Página ───────────────────────────────────────────────────────────────────

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(_expenseCategoriesProvider);
    final budgetsAsync = ref.watch(budgetMapProvider);
    final groupId = ref.watch(activeGroupIdProvider);
    final spentAsync = ref.watch(expenseByCategoryProvider(groupId: groupId));

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).budgetPageTitle)),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          final budgets = budgetsAsync.valueOrNull ?? {};
          final spent = spentAsync.valueOrNull ?? {};

          // ── Totales globales ────────────────────────────────────────────
          final totalBudget =
              budgets.values.fold(0.0, (s, v) => s + v);
          final totalSpent = cats.fold(
            0.0,
            (s, cat) => s + (spent[cat.id] ?? 0.0),
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              if (totalBudget > 0)
                _BudgetSummaryCard(
                  totalBudget: totalBudget,
                  totalSpent: totalSpent,
                ),
              const _InfoBanner(),
              const SizedBox(height: AppSpacing.md),
              ...cats.map((cat) {
                final limit = budgets[cat.id] ?? 0.0;
                final gastado = spent[cat.id] ?? 0.0;
                return _BudgetTile(
                  cat: cat,
                  limit: limit,
                  gastado: gastado,
                  onEdit: () => _editBudget(context, ref, cat, limit),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData cat,
    double current,
  ) async {
    final ctrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).budgetDialogTitle(cat.name)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: S.of(context).budgetLimitLabel,
            prefixText: '\$ ',
            helperText: S.of(context).budgetLimitHelper,
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
                Navigator.pop(dialogContext, double.tryParse(ctrl.text) ?? 0),
            child: Text(S.of(context).saveButton),
          ),
        ],
      ),
    );
    if (result != null) {
      if (result <= 0) {
        await ref.read(budgetNotifierProvider.notifier).removeBudget(cat.id);
      } else {
        await ref.read(budgetNotifierProvider.notifier).setBudget(
              categoryId: cat.id,
              monthlyLimit: result,
            );
      }
    }
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
  });
  final double totalBudget;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final progress = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final isOver = totalSpent > totalBudget;
    final barColor = isOver
        ? AppColors.budgetOver
        : progress >= 0.8
            ? AppColors.budgetWarning
            : AppColors.budgetOk;

    return Card(
      color: barColor.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).budgetMonthSummary,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  S.of(context).percentUsed((progress * 100).toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: barColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryChip(
                  label: S.of(context).spentLabel,
                  value: '\$ ${totalSpent.toStringAsFixed(2)}',
                  color: AppColors.expense,
                ),
                _SummaryChip(
                  label: S.of(context).budgetedLabel,
                  value: '\$ ${totalBudget.toStringAsFixed(2)}',
                  color: AppColors.primary,
                ),
                _SummaryChip(
                  label: isOver ? S.of(context).exceededLabel : S.of(context).availableLabel,
                  value: isOver
                      ? '-\$ ${(totalSpent - totalBudget).toStringAsFixed(2)}'
                      : '\$ ${remaining.toStringAsFixed(2)}',
                  color: isOver ? AppColors.budgetOver : AppColors.income,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  S.of(context).budgetInfo,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.cat,
    required this.limit,
    required this.gastado,
    required this.onEdit,
  });
  final CategoriesTableData cat;
  final double limit;
  final double gastado;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final catColor = colorFromHex(cat.colorHex);
    final hasLimit = limit > 0;
    final progress = hasLimit ? (gastado / limit).clamp(0.0, 1.0) : 0.0;
    final barColor = !hasLimit
        ? AppColors.primary
        : progress >= 1.0
            ? AppColors.budgetOver
            : progress >= 0.8
                ? AppColors.budgetWarning
                : AppColors.budgetOk;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: catColor.withValues(alpha: 0.12),
                  child: Icon(
                    iconFromCode(cat.iconCode),
                    color: catColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      hasLimit
                          ? Text(
                              '\$ ${gastado.toStringAsFixed(2)} de \$ ${limit.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: barColor),
                            )
                          : Text(
                              S.of(context).noLimitDefined,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textDisabled),
                            ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                ),
              ],
            ),
            if (hasLimit) ...[
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: barColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
