import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../data/local/app_database.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../../../router/app_router.dart';
import 'csv_import_page.dart';

// ── Paleta de colores para cuentas ───────────────────────────────────────────

const _kAccountColors = [
  '#607D8B', // blue-grey (default)
  '#2196F3', // blue
  '#4CAF50', // green
  '#FF9800', // orange
  '#9C27B0', // purple
  '#F44336', // red
  '#00BCD4', // cyan
  '#795548', // brown
  '#FF5722', // deep-orange
  '#009688', // teal
];

const _kAccountIcons = [
  ('account_balance_wallet', 'Billetera'),
  ('account_balance', 'Banco'),
  ('savings', 'Ahorros'),
  ('credit_card', 'Tarjeta'),
  ('payments', 'Pagos'),
  ('attach_money', 'Efectivo'),
  ('phone_android', 'Digital'),
  ('trending_up', 'Ahorros'),
  ('store', 'Negocio'),
  ('home', 'Casa'),
];

const _kAccountTypes = [
  ('cash', 'Efectivo'),
  ('bank', 'Cuenta bancaria'),
  ('digital', 'Billetera digital'),
  ('credit', 'Tarjeta de crédito'),
  ('investment', 'Ahorros'),
];

String _accountTypeLabel(BuildContext context, String type) => switch (type) {
      'cash' => S.of(context).acctTypeCash,
      'bank' => S.of(context).acctTypeBank,
      'digital' => S.of(context).acctTypeDigital,
      'credit' => S.of(context).acctTypeCredit,
      'investment' => S.of(context).acctTypeInvestment,
      _ => type,
    };

String _accountIconLabel(BuildContext context, String code) => switch (code) {
      'account_balance_wallet' => S.of(context).acctIconWallet,
      'account_balance' => S.of(context).acctIconBank,
      'savings' => S.of(context).acctIconSavings,
      'credit_card' => S.of(context).acctIconCard,
      'payments' => S.of(context).acctIconPayments,
      'attach_money' => S.of(context).acctIconCash,
      'phone_android' => S.of(context).acctIconDigital,
      'trending_up' => S.of(context).acctIconInvestment,
      'store' => S.of(context).acctIconBusiness,
      'home' => S.of(context).acctIconHome,
      _ => code,
    };

// ── Page principal ────────────────────────────────────────────────────────────

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).accountsTitle)),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(S.of(context).errorGenericDetail(e.toString()))),
        data: (accounts) => accounts.isEmpty
            ? _EmptyState(onNew: () => _openForm(context, ref, null))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: accounts.length,
                itemBuilder: (ctx, i) => _AccountTile(
                  account: accounts[i],
                  onEdit: () => _openForm(context, ref, accounts[i]),
                  onArchive: () => ref
                      .read(accountsNotifierProvider.notifier)
                      .archive(accounts[i].id),
                  onImportCsv: () => _openCsvImport(
                    context,
                    accounts[i].id,
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final accounts = accountsAsync.valueOrNull ?? [];
          final isPremium = ref.read(isPremiumProvider);
          if (accounts.isNotEmpty && !isPremium) {
            context.push(AppRoutes.paywall);
            return;
          }
          _openForm(context, ref, null);
        },
        icon: const Icon(Icons.add),
        label: Text(S.of(context).newAccount),
      ),
    );
  }

  Future<void> _openCsvImport(
    BuildContext context,
    String accountId,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CsvImportPage(preselectedAccountId: accountId),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    AccountsTableData? existing,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AccountFormDialog(
        existing: existing,
        onSave: (name, type, currency, initialBalance, colorHex, iconCode) {
          final notifier = ref.read(accountsNotifierProvider.notifier);
          if (existing == null) {
            notifier.create(
              name: name,
              type: type,
              currencyCode: currency,
              initialBalance: initialBalance,
              colorHex: colorHex,
              iconCode: iconCode,
            );
          } else {
            notifier.updateAccount(
              existing.copyWith(
                name: name,
                type: type,
                currencyCode: currency,
                initialBalance: initialBalance,
                colorHex: colorHex,
                iconCode: iconCode,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _AccountTile extends ConsumerWidget {
  const _AccountTile({
    required this.account,
    required this.onEdit,
    required this.onArchive,
    required this.onImportCsv,
  });

  final AccountsTableData account;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onImportCsv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorFromHex(account.colorHex);
    final icon = iconFromCode(account.iconCode);
    final typeLabel = _accountTypeLabel(context, account.type);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$typeLabel · ${account.currencyCode}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BalanceChip(accountId: account.id),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              tooltip: S.of(context).editButton,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              onPressed: onImportCsv,
              tooltip: S.of(context).importCsvButton,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined, size: 18),
              onPressed: onArchive,
              tooltip: S.of(context).archiveButton,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance chip ──────────────────────────────────────────────────────────────

class _BalanceChip extends ConsumerWidget {
  const _BalanceChip({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<double>(
      future: db.accountsDao.getBalance(accountId),
      builder: (context, snap) {
        final balance = snap.data ?? 0.0;
        final isPositive = balance >= 0;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.income : AppColors.expense)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.income : AppColors.expense,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).noAccounts,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).addAccount),
            ),
          ],
        ),
      );
}

// ── Formulario de alta/edición ────────────────────────────────────────────────

class _AccountFormDialog extends StatefulWidget {
  const _AccountFormDialog({this.existing, required this.onSave});

  final AccountsTableData? existing;
  final void Function(
    String name,
    String type,
    String currency,
    double initialBalance,
    String colorHex,
    String iconCode,
  ) onSave;

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late String _type;
  late String _currency;
  late String _colorHex;
  late String _iconCode;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: e != null ? e.initialBalance.toStringAsFixed(2) : '0.00',
    );
    _type = e?.type ?? 'cash';
    _currency = e?.currencyCode ?? 'USD';
    _colorHex = e?.colorHex ?? '#607D8B';
    _iconCode = e?.iconCode ?? 'account_balance_wallet';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final balance = double.tryParse(
          _balanceCtrl.text.replaceAll(',', '.'),
        ) ??
        0.0;
    widget.onSave(
      _nameCtrl.text.trim(),
      _type,
      _currency,
      balance,
      _colorHex,
      _iconCode,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? S.of(context).editAccount : S.of(context).newAccount),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.of(context).nameLabel),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Tipo
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: S.of(context).fieldType),
              items: _kAccountTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.$1,
                      child: Text(_accountTypeLabel(context, t.$1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Moneda
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: S.of(context).currencyFieldLabel),
              items: ['USD', 'VES', 'EUR', 'COP']
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Balance inicial
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: S.of(context).initialBalanceLabel,
                helperText: S.of(context).initialBalanceHelper,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color
            Text(
              S.of(context).colorLabel,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kAccountColors.map((hex) {
                final color = colorFromHex(hex);
                final selected = _colorHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                              width: 2.5,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Ícono
            Text(
              S.of(context).iconLabel,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kAccountIcons.map((entry) {
                final selected = _iconCode == entry.$1;
                final accent = colorFromHex(_colorHex);
                return GestureDetector(
                  onTap: () => setState(() => _iconCode = entry.$1),
                  child: Tooltip(
                    message: _accountIconLabel(context, entry.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconFromCode(entry.$1),
                        size: 20,
                        color: selected ? accent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancelButton),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? S.of(context).saveButton : S.of(context).createButton),
        ),
      ],
    );
  }
}
