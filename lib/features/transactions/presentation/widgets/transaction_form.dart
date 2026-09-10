import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../data/local/app_database.dart';
import '../../../accounts/providers/accounts_provider.dart';
import '../../../categories/presentation/dialogs/category_creation_dialog.dart';
import '../../../family/providers/family_provider.dart';
import '../../../settings/providers/ocr_settings_provider.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/providers/display_prefs_provider.dart';
import '../../providers/transactions_provider.dart';

// ── Función de apertura reutilizable ─────────────────────────────────────────
// Llamable desde AdaptiveScaffold, TransactionsPage o cualquier widget.

Future<void> openTransactionForm(
  BuildContext context, [
  TransactionsTableData? existing,
]) async {
  final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  final s = S.of(context);
  final title = existing == null ? s.newTransactionTitle : s.editTransactionTitle;

  if (isDesktop) {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(title),
            leading: const BackButton(),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TransactionForm(existing: existing),
            ),
          ),
        ),
      ),
    );
  } else {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(title),
            leading: const BackButton(),
          ),
          body: TransactionForm(existing: existing),
        ),
      ),
    );
  }
}

// ── Widget del formulario ─────────────────────────────────────────────────────

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.existing});
  final TransactionsTableData? existing;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense';
  String _currency = 'USD';
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _accountId;
  bool _ocrLoading = false;
  String _rateType = 'parallel';
  String _arsRate = 'blue';
  String? _ocrCategoryHint;

  // Monedas soportadas por la aplicación.
  static const _kCurrencies = ['USD', 'VES', 'EUR', 'MXN', 'ARS'];

  List<CategoriesTableData> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing case final tx?) {
      _type = tx.type;
      _currency = tx.currencyCode;
      _date = tx.date;
      _categoryId = tx.categoryId;
      _accountId = tx.accountId;
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _descCtrl.text = tx.description ?? '';
    } else {
      // Transacción nueva: usar la moneda principal del usuario por defecto.
      _currency = ref.read(displayPrefsProvider).primaryCurrency;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final db = ref.read(appDatabaseProvider);
    final groupId = ref.read(activeGroupIdProvider);
    final cats = await db.categoriesDao.getCategoriesForGroup(groupId);
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _pickAndOcr() async {
    // Gate premium
    if (!ref.read(isPremiumProvider)) {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      );
      return;
    }
    // Pro sin backend propio → usa el proxy del desarrollador (sin configurar nada)
    // Pro con backend configurado → usa BYOK
    // Free sin backend → no llega aquí (bloqueado arriba)
    final settings = ref.read(ocrSettingsProvider);
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium && !settings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).ocrConfigPrompt,
          ),
        ),
      );
      return;
    }

    final (bytes, mime) = await _pickImageBytes();
    if (bytes == null || !mounted) return;

    setState(() => _ocrLoading = true);
    try {
      final service = ref.read(ocrServiceProvider);
      final result = await service.extractFromImage(bytes, mime);

      if (!mounted) return;
      if (result.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).ocrErrorMsg(result.error ?? '')),
            backgroundColor: AppColors.expense,
          ),
        );
        return;
      }
      _applyOcrResult(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).ocrExtracted),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  Future<(Uint8List?, String)> _pickImageBytes() async {
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      final typeGroup = XTypeGroup(
        label: S.of(context).imagesLabel,
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return (null, '');
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      return (bytes, mime);
    } else {
      // En móvil: ofrecer cámara o galería
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(S.of(context).takePhoto),
                onTap: () => Navigator.pop(_, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(S.of(context).chooseFromGallery),
                onTap: () => Navigator.pop(_, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return (null, '');
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image == null) return (null, '');
      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? 'image/jpeg';
      return (bytes, mime);
    }
  }

  void _applyOcrResult(OcrResult result) {
    setState(() {
      if (result.amount != null) {
        _amountCtrl.text = result.amount!.toStringAsFixed(2);
      }
      if (result.description != null && result.description!.isNotEmpty) {
        _descCtrl.text = result.description!;
      }
      if (result.currency != null) {
        final cur = result.currency!.toUpperCase();
        if (_kCurrencies.contains(cur)) _currency = cur;
      }
      if (result.date != null) _date = result.date!;
      if (result.categoryHint != null) {
        final catId = _hintToCategory(result.categoryHint!);
        if (catId != null) {
          _categoryId = catId;
          _ocrCategoryHint = null;
        } else {
          _ocrCategoryHint = result.categoryHint!;
        }
      }
      _type = 'expense';
    });
  }

  String? _hintToCategory(String hint) => switch (hint.toLowerCase()) {
        'food' => 'sys_food',
        'transport' => 'sys_transport',
        'services' => 'sys_services',
        'health' => 'sys_health',
        'education' => 'sys_education',
        'entertainment' => 'sys_entertainment',
        'clothing' => 'sys_clothing',
        'home' => 'sys_home',
        'debt' => 'sys_debt',
        _ => null,
      };

  String _hintDisplayName(BuildContext context, String hint) =>
      switch (hint.toLowerCase()) {
        'pharmacy' => S.of(context).catPharmacy,
        'gym' => S.of(context).catGym,
        'sport' || 'sports' => S.of(context).catSport,
        'beauty' => S.of(context).catBeauty,
        'travel' => S.of(context).catTravel,
        'hotel' => S.of(context).catHotel,
        'fuel' || 'gas' => S.of(context).catFuel,
        'technology' || 'tech' => S.of(context).catTechnology,
        'pets' => S.of(context).catPets,
        'gifts' || 'gift' => S.of(context).catGifts,
        'coffee' => S.of(context).catCoffee,
        'bakery' => S.of(context).catBakery,
        'market' => S.of(context).catMarket,
        'hardware' => S.of(context).catHardware,
        _ => hint,
      };

  Future<void> _createCategoryFromHint(BuildContext context) async {
    final hint = _ocrCategoryHint;
    if (hint == null) return;
    final cat = await showDialog<CategoriesTableData>(
      context: context,
      builder: (_) => CategoryCreationDialog(
        initialName: _hintDisplayName(context, hint),
        initialType: 'expense',
      ),
    );
    if (cat != null && mounted) {
      await _loadCategories();
      setState(() {
        _categoryId = cat.id;
        _ocrCategoryHint = null;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(transactionNotifierProvider).isLoading;
    final cats = _categories.where((c) => c.type == _type).toList();

    final s = S.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? s.newTransactionTitle
                        : s.editTransactionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_ocrLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _pickAndOcr,
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(s.scanReceiptButton),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TxTypeBtn(
                  label: s.expenseTypeButton,
                  icon: Icons.arrow_upward,
                  active: _type == 'expense',
                  color: AppColors.expense,
                  onTap: () => setState(() {
                    _type = 'expense';
                    _categoryId = null;
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                TxTypeBtn(
                  label: s.incomeTypeButton,
                  icon: Icons.arrow_downward,
                  active: _type == 'income',
                  color: AppColors.income,
                  onTap: () => setState(() {
                    _type = 'income';
                    _categoryId = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: s.amountLabel,
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return s.amountValidationEmpty;
                if (double.tryParse(v) == null) return s.amountValidationInvalid;
                if (double.parse(v) <= 0) return s.amountValidationPositive;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(s.currencyInline,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kCurrencies
                  .map(
                    (c) => _CurrencyChip(
                      label: c,
                      active: _currency == c,
                      onTap: () => setState(() => _currency = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_currency == 'VES')
              VesRateBanner(
                rateType: _rateType,
                onRateTypeChanged: (v) => setState(() => _rateType = v),
              ),
            if (_currency == 'ARS')
              ArsRateBanner(
                rateType: _arsRate,
                onRateTypeChanged: (v) => setState(() => _arsRate = v),
              ),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: s.descriptionOptional,
                hintText: s.descriptionHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('es'),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(DateFormat('d MMMM yyyy', 'es').format(_date)),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (cats.isNotEmpty || _ocrCategoryHint != null) ...[
              Text(s.categoryLabel, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cats.map((cat) {
                  final sel = _categoryId == cat.id;
                  final color = colorFromHex(cat.colorHex);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _categoryId = sel ? null : cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? color
                            : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? color
                              : color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconFromCode(cat.iconCode),
                            size: 14,
                            color: sel ? Colors.white : color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryDisplayName(context, cat.id, cat.name),
                            style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.white : color,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_ocrCategoryHint != null)
                GestureDetector(
                  onTap: () => _createCategoryFromHint(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          S.of(context)
                              .createCategoryQuoted(_hintDisplayName(context, _ocrCategoryHint!)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Cuenta
            _AccountPicker(
              selectedId: _accountId,
              onChanged: (id) => setState(() => _accountId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        saving ? null : () => Navigator.pop(context),
                    child: Text(s.cancelButton),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.saveButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);

    double? usdEquiv;
    if (_currency == 'VES') {
      final manualVes = ref.read(displayPrefsProvider).manualVesRate;
      if (manualVes > 0) {
        usdEquiv = amount / manualVes;
      } else {
        final rates = ref.read(vesRatesProvider).valueOrNull;
        if (rates != null && rates.bcv > 0) {
          final rate = _rateType == 'bcv' ? rates.bcv : rates.parallel;
          if (rate > 0) usdEquiv = amount / rate;
        }
      }
    } else if (_currency == 'EUR') {
      final rates = ref.read(vesRatesProvider).valueOrNull;
      final usdPerEur = rates?.usdPerEur ?? 0; // forex real EUR/USD
      if (usdPerEur > 0) usdEquiv = amount * usdPerEur;
    } else if (_currency == 'MXN') {
      final rates = ref.read(vesRatesProvider).valueOrNull;
      final r = rates?.usdMxn ?? 0;
      if (r > 0) usdEquiv = amount / r;
    } else if (_currency == 'ARS') {
      final rates = ref.read(vesRatesProvider).valueOrNull;
      final r = _arsRate == 'oficial'
          ? (rates?.usdArsOficial ?? 0)
          : (rates?.usdArsBlue ?? 0);
      if (r > 0) usdEquiv = amount / r;
    } else {
      usdEquiv = amount;
    }

    final ok = await ref.read(transactionNotifierProvider.notifier).save(
          existingId: widget.existing?.id,
          type: _type,
          amount: amount,
          currencyCode: _currency,
          date: _date,
          categoryId: _categoryId,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          amountUsdEquivalent: usdEquiv,
          accountId: _accountId,
        );
    if (ok && mounted) Navigator.pop(context);
  }
}

// ── Selector de cuenta ────────────────────────────────────────────────────────

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).accountLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                hintText: S.of(context).noAccountOption,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    S.of(context).noAccountOption,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ...accounts.map(
                  (a) => DropdownMenuItem<String>(
                    value: a.id,
                    child: Row(
                      children: [
                        Icon(
                          iconFromCode(a.iconCode),
                          size: 16,
                          color: colorFromHex(a.colorHex),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(a.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }
}

// ── Botón de tipo ─────────────────────────────────────────────────────────────

class TxTypeBtn extends StatelessWidget {
  const TxTypeBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? color : AppColors.border,
                width: active ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: active ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Banner tasas VES ──────────────────────────────────────────────────────────

class VesRateBanner extends ConsumerWidget {
  const VesRateBanner({
    super.key,
    required this.rateType,
    required this.onRateTypeChanged,
  });

  final String rateType;
  final ValueChanged<String> onRateTypeChanged;

  static String _fmtTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(vesRatesProvider);
    final fmt = NumberFormat('#,##0.00', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ratesAsync.when(
        loading: () => Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).rateLoading,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        error: (_, __) => Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              size: 14,
              color: AppColors.expense,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).rateUnavailable,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        data: (rates) {
          if (rates == null ||
              (rates.bcv <= 0 && rates.parallel <= 0)) {
            return Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  size: 14,
                  color: AppColors.expense,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  S.of(context).rateUnavailable,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.expense,
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap: si no cabe en una línea, baja a la siguiente en vez de
              // cortar el texto (evita overflow en pantallas angostas).
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.currency_exchange,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'BCV: Bs. ${fmt.format(rates.bcv)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${S.of(context).rateParallel}: Bs. ${fmt.format(rates.parallel)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    S.of(context).rateUpdated(_fmtTimeAgo(rates.updatedAt)),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  Text(
                    S.of(context).rateUseLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _RateToggleChip(
                    label: 'BCV',
                    active: rateType == 'bcv',
                    onTap: () => onRateTypeChanged('bcv'),
                  ),
                  _RateToggleChip(
                    label: S.of(context).rateParallel,
                    active: rateType == 'parallel',
                    onTap: () => onRateTypeChanged('parallel'),
                  ),
                  Builder(
                    builder: (ctx) {
                      final rate =
                          rateType == 'bcv' ? rates.bcv : rates.parallel;
                      return Text(
                        '1 USD = Bs. ${fmt.format(rate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RateToggleChip extends StatelessWidget {
  const _RateToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── Chip de moneda ────────────────────────────────────────────────────────────

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: active ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── Banner tasas ARS (oficial / blue) ─────────────────────────────────────────

class ArsRateBanner extends ConsumerWidget {
  const ArsRateBanner({
    super.key,
    required this.rateType,
    required this.onRateTypeChanged,
  });

  final String rateType; // 'oficial' | 'blue'
  final ValueChanged<String> onRateTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(vesRatesProvider);
    final fmt = NumberFormat('#,##0.00', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ratesAsync.when(
        loading: () => Text(
          S.of(context).rateLoading,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        error: (_, __) => Text(
          S.of(context).rateUnavailable,
          style: const TextStyle(fontSize: 12, color: AppColors.expense),
        ),
        data: (rates) {
          final oficial = rates?.usdArsOficial ?? 0;
          final blue = rates?.usdArsBlue ?? 0;
          if (oficial <= 0 && blue <= 0) {
            return Text(
              S.of(context).rateUnavailable,
              style: const TextStyle(fontSize: 12, color: AppColors.expense),
            );
          }
          final selected = rateType == 'oficial' ? oficial : blue;
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              Text(
                S.of(context).rateUseLabel,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              _RateToggleChip(
                label: 'Oficial',
                active: rateType == 'oficial',
                onTap: () => onRateTypeChanged('oficial'),
              ),
              _RateToggleChip(
                label: 'Blue',
                active: rateType == 'blue',
                onTap: () => onRateTypeChanged('blue'),
              ),
              if (selected > 0)
                Text(
                  '1 USD = ARS ${fmt.format(selected)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
