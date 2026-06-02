import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../data/local/app_database.dart';
import '../../../accounts/providers/accounts_provider.dart';
import '../../../family/providers/family_provider.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../../../router/app_router.dart';
import '../widgets/transaction_form.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/transfer_form_dialog.dart';

String _fmtTxMoney(double v) => NumberFormat('#,##0.00', 'es').format(v);
String _fmtTxDate(DateTime d) => DateFormat('EEE d MMM', 'es').format(d);

// ── Página principal ──────────────────────────────────────────────────────────

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'all';
  String _searchQuery = '';
  String? _categoryFilter; // null = todas
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  int _txLimit = kTxPageSize;

  void _prevMonth() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _txLimit = kTxPageSize; // reset al cambiar mes
      });

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      setState(() {
        _month = next;
        _txLimit = kTxPageSize;
      });
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TransactionsTableData> _applyFilters(
    List<TransactionsTableData> txs,
    List<CategoriesTableData> cats,
  ) {
    var result = txs;

    // Filtro por tipo
    if (_filter != 'all') {
      result = result.where((t) => t.type == _filter).toList();
    }

    // Filtro por categoría
    if (_categoryFilter != null) {
      result = result.where((t) => t.categoryId == _categoryFilter).toList();
    }

    // Búsqueda por texto (descripción o nombre de categoría)
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final catNames = {for (final c in cats) c.id: c.name.toLowerCase()};
      result = result.where((t) {
        final desc = (t.description ?? '').toLowerCase();
        final catName = catNames[t.categoryId ?? ''] ?? '';
        return desc.contains(q) || catName.contains(q);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'es').format(_month);
    final monthArgs = (year: _month.year, month: _month.month);
    final listArgs = (year: _month.year, month: _month.month, limit: _txLimit);
    final stream = ref.watch(transactionListProvider(listArgs));
    final totalCount =
        ref.watch(transactionCountProvider(monthArgs)).valueOrNull ?? 0;

    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(label[0].toUpperCase() + label.substring(1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: s.recurringTooltip,
            onPressed: () => context.push(AppRoutes.recurring),
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
            ),
            tooltip: _showSearch ? 'Cerrar búsqueda' : s.searchTooltip,
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: s.exportTooltip,
            onSelected: (format) => _exportReport(context, ref, format, stream),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(s.exportPdf),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(s.exportCsv),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isCurrentMonth ? null : _nextMonth,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda (animada)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showSearch
                ? _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : const SizedBox.shrink(),
          ),
          _FilterBar(
            selected: _filter,
            onChanged: (v) => setState(() => _filter = v),
            categoryFilter: _categoryFilter,
            onCategoryFilter: (id) => setState(() => _categoryFilter = id),
          ),
          Expanded(child: _buildList(context, stream, totalCount)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_transfer',
            onPressed: () => openTransferForm(context),
            tooltip: s.transferTitle,
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'fab_add',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: Text(s.registerButton),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncValue<List<TransactionsTableData>> stream,
    int totalCount,
  ) {
    final db = ref.watch(appDatabaseProvider);
    final groupId = ref.watch(activeGroupIdProvider);

    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txs) {
        return FutureBuilder<List<CategoriesTableData>>(
          future: db.categoriesDao.getCategoriesForGroup(groupId),
          builder: (_, catSnap) {
            final cats = catSnap.data ?? [];
            final filtered = _applyFilters(txs, cats);
            final hasMore = totalCount > _txLimit;
            return _buildFilteredList(context, filtered, hasMore: hasMore);
          },
        );
      },
    );
  }

  Widget _buildFilteredList(
    BuildContext context,
    List<TransactionsTableData> filtered, {
    bool hasMore = false,
  }) {
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  S.of(context).noTransactions,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final Map<String, List<TransactionsTableData>> byDate = {};
        for (final tx in filtered) {
          final key = DateFormat('yyyy-MM-dd').format(tx.date);
          byDate.putIfAbsent(key, () => []).add(tx);
        }
        final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.md,
            bottom: 100,
          ),
          // +1 para el footer de paginación si hay más
          itemCount: dates.length + (hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            // Footer "Ver más"
            if (i == dates.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _txLimit += kTxPageSize,
                    ),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(
                      'Ver más (mostrando $_txLimit de ${_txLimit > 0 ? "$_txLimit+" : "..."})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              );
            }
            final date = dates[i];
            final group = byDate[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    _fmtTxDate(DateTime.parse(date)),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int j = 0; j < group.length; j++) ...[
                        _TxTile(
                          tx: group[j],
                          onEdit: () => _openForm(context, group[j]),
                          onDelete: () => _confirmDelete(context, group[j].id),
                        ),
                        if (j < group.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        );
  }

  Future<void> _exportReport(
    BuildContext context,
    WidgetRef ref,
    String format,
    AsyncValue<List<TransactionsTableData>> stream,
  ) async {
    // Gate premium
    if (!ref.read(isPremiumProvider)) {
      context.push(AppRoutes.paywall);
      return;
    }
    final txs = stream.valueOrNull ?? [];
    if (txs.isEmpty && format == 'pdf') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).noTransactionsExport),
        ),
      );
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final groupId = ref.read(activeGroupIdProvider);
    final cats = await db.categoriesDao.getCategoriesForGroup(groupId);
    if (!context.mounted) return;
    await ExportService.exportMonthlyReport(
      context: context,
      format: format,
      year: _month.year,
      month: _month.month,
      transactions: txs,
      categories: cats,
    );
  }

  Future<void> _openForm(
    BuildContext context, [
    TransactionsTableData? tx,
  ]) => openTransactionForm(context, tx);

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).deleteTransactionTitle),
        content: Text(
          S.of(context).deleteTransactionConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              S.of(context).deleteButton,
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(transactionNotifierProvider.notifier).delete(id);
    }
  }
}

// ── Barra de búsqueda ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          0,
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: true,
          decoration: InputDecoration(
            hintText: S.of(context).searchTransactionsHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
}

// ── Barra de filtro ───────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.categoryFilter,
    required this.onCategoryFilter,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final typeOptions = [
      ('all', s.filterAll),
      ('income', s.filterIncome),
      ('expense', s.filterExpense),
      ('transfer', s.filterTransfer),
    ];

    final groupId = ref.watch(activeGroupIdProvider);
    final db = ref.watch(appDatabaseProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Chips de tipo
          ...typeOptions.map((opt) {
            final (value, label) = opt;
            final active = selected == value;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // Filtro de categoría
          FutureBuilder<List<CategoriesTableData>>(
            future: db.categoriesDao.getCategoriesForGroup(groupId),
            builder: (_, snap) {
              final cats = snap.data ?? [];
              if (cats.isEmpty) return const SizedBox.shrink();
              final active = categoryFilter != null;
              return GestureDetector(
                onTap: () => _showCategoryPicker(context, cats),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 14,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        active
                            ? (cats
                                    .where((c) => c.id == categoryFilter)
                                    .firstOrNull
                                    ?.name ??
                                s.categoryLabel)
                            : s.categoryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onCategoryFilter(null),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    List<CategoriesTableData> cats,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(S.of(context).filterByCategory),
        children: cats
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, c.id),
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
            )
            .toList(),
      ),
    );
    if (picked != null) onCategoryFilter(picked);
  }
}

// ── Tile de transacción ───────────────────────────────────────────────────────

class _TxTile extends ConsumerStatefulWidget {
  const _TxTile({
    required this.tx,
    required this.onDelete,
    required this.onEdit,
  });
  final TransactionsTableData tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  ConsumerState<_TxTile> createState() => _TxTileState();
}

class _TxTileState extends ConsumerState<_TxTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.tx.type == 'transfer';
    final isIncome = widget.tx.type == 'income';

    // Color y ícono según tipo
    final Color color;
    final IconData leadingIcon;
    final String amountPrefix;
    if (isTransfer) {
      final meta = parseTransferMeta(widget.tx.notes);
      color = AppColors.textSecondary;
      leadingIcon = (meta?.isOutgoing ?? true)
          ? Icons.arrow_outward
          : Icons.arrow_downward;
      amountPrefix = meta?.isOutgoing == false ? '+' : '→';
    } else if (isIncome) {
      color = AppColors.income;
      leadingIcon = Icons.arrow_downward;
      amountPrefix = '+';
    } else {
      color = AppColors.expense;
      leadingIcon = Icons.arrow_upward;
      amountPrefix = '-';
    }

    // Subtítulo: para transferencias muestra "de/hacia [nombre]"
    Widget? subtitleWidget;
    if (isTransfer) {
      final meta = parseTransferMeta(widget.tx.notes);
      if (meta != null) {
        subtitleWidget = Text(
          meta.isOutgoing
              ? '→ ${meta.peerName}'
              : '← ${meta.peerName}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        );
      }
    } else {
      final hasCategory = widget.tx.categoryId != null;
      final hasAccount = widget.tx.accountId != null;
      if (hasCategory || hasAccount) {
        subtitleWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCategory)
              _CategoryLabel(categoryId: widget.tx.categoryId!),
            if (hasCategory && hasAccount)
              const Text(
                '  ·  ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textDisabled,
                ),
              ),
            if (hasAccount)
              _AccountLabel(accountId: widget.tx.accountId!),
          ],
        );
      }
    }

    // Título por defecto si no hay descripción
    String titleText;
    if (widget.tx.description != null && widget.tx.description!.isNotEmpty) {
      titleText = widget.tx.description!;
    } else if (isTransfer) {
      final meta = parseTransferMeta(widget.tx.notes);
      titleText = meta?.isOutgoing == true ? 'Transferencia enviada' : 'Transferencia recibida';
    } else {
      titleText = isIncome ? S.of(context).incomeTypeButton : S.of(context).expenseTypeButton;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ListTile(
        onTap: isTransfer ? null : widget.onEdit,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: isTransfer ? 0.08 : 0.12),
          child: Icon(
            isTransfer ? Icons.swap_horiz : leadingIcon,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          titleText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTransfer ? AppColors.textSecondary : null,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitleWidget,
        trailing: _hovered && !isTransfer
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    tooltip: S.of(context).editButton,
                    onPressed: widget.onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                      size: 18,
                    ),
                    tooltip: S.of(context).deleteButton,
                    onPressed: widget.onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )
            : Text(
                '$amountPrefix ${widget.tx.currencyCode} ${_fmtTxMoney(widget.tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
      ),
    );
  }
}

class _CategoryLabel extends ConsumerWidget {
  const _CategoryLabel({required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(activeGroupIdProvider);
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<CategoriesTableData>>(
      future: db.categoriesDao.getCategoriesForGroup(groupId),
      builder: (_, snap) {
        final cat = snap.data?.where((c) => c.id == categoryId).firstOrNull;
        if (cat == null) return const SizedBox.shrink();
        return Text(
          cat.name,
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

class _AccountLabel extends ConsumerWidget {
  const _AccountLabel({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        final account =
            accounts.where((a) => a.id == accountId).firstOrNull;
        if (account == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconFromCode(account.iconCode),
              size: 11,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: 3),
            Text(
              account.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
            ),
          ],
        );
      },
    );
  }
}

