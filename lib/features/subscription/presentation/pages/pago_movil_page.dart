import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/services/payment_request_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATOS DE PAGO MÓVIL — ⚠️ COMPLETAR CON TUS DATOS REALES ANTES DE USAR
// Estos son los datos a los que el usuario envía el Pago Móvil.
// ══════════════════════════════════════════════════════════════════════════════
const String _kPmBanco = '0102 · Banco de Venezuela';
const String _kPmTelefono = '0000-0000000';
const String _kPmDocumento = 'V-00.000.000';
const String _kPmTitular = 'Titular de la cuenta';

/// Precio anual de Premium. ⚠️ Ajusta si defines otro precio.
const double _kPremiumAnnualUsd = 99.99;

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

String _money(double v) => NumberFormat('#,##0.00', 'es').format(v);

// ── Opción de plan ────────────────────────────────────────────────────────────

class _PlanOption {
  const _PlanOption(
      this.key, this.planName, this.billing, this.title, this.usd);
  final String key;
  final String planName; // 'family' | 'premium'
  final String billing; // 'monthly' | 'annual'
  final String title;
  final double usd;
}

const List<_PlanOption> _kPlans = [
  _PlanOption('family_monthly', 'family', 'monthly', 'Familiar · mensual', 2.99),
  _PlanOption('family_annual', 'family', 'annual', 'Familiar · anual', 19.99),
  _PlanOption(
      'premium_monthly', 'premium', 'monthly', 'Premium · mensual', 9.99),
  _PlanOption(
      'premium_annual', 'premium', 'annual', 'Premium · anual', _kPremiumAnnualUsd),
];

// ── Página ────────────────────────────────────────────────────────────────────

class PagoMovilPage extends ConsumerStatefulWidget {
  const PagoMovilPage({super.key});

  @override
  ConsumerState<PagoMovilPage> createState() => _PagoMovilPageState();
}

class _PagoMovilPageState extends ConsumerState<PagoMovilPage> {
  String _selectedKey = 'family_monthly';
  final _refCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  PaymentRequest? _latest;
  bool _loadingLatest = true;

  _PlanOption get _selected =>
      _kPlans.firstWhere((p) => p.key == _selectedKey, orElse: () => _kPlans.first);

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    try {
      final r = await PaymentRequestService.instance.latest();
      if (mounted) setState(() { _latest = r; _loadingLatest = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLatest = false);
    }
  }

  double? _vesFor(double usd) {
    final rate = ref.read(vesRatesProvider).valueOrNull?.parallel ?? 0;
    return rate > 0 ? usd * rate : null;
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _submit() async {
    final reference = _refCtrl.text.trim();
    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el número de referencia del pago.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final plan = _selected;
    final ves = _vesFor(plan.usd);
    try {
      await PaymentRequestService.instance.submit(
        planName: plan.planName,
        billing: plan.billing,
        amountUsd: plan.usd,
        amountVes: ves,
        reference: reference,
        payerName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        payerPhone:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      _refCtrl.clear();
      await _loadLatest();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle,
              color: AppColors.income, size: 40),
          title: const Text('Reporte enviado'),
          content: const Text(
            'Recibimos tu reporte de pago. En cuanto confirmemos el pago móvil '
            'activaremos tu plan. Puedes cerrar esta pantalla; el plan se '
            'reflejará automáticamente cuando esté aprobado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el reporte: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se observa para reconstruir cuando lleguen/actualicen las tasas de cambio.
    ref.watch(vesRatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar con Pago Móvil')),
      body: _isMobile ? const _MobileNotice() : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final plan = _selected;
    final ves = _vesFor(plan.usd);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (!_loadingLatest && _latest != null) ...[
          _StatusBanner(request: _latest!),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 1. Elegir plan
        const _StepTitle(1, 'Elige tu plan'),
        const SizedBox(height: AppSpacing.sm),
        ..._kPlans.map((p) => _PlanTile(
              option: p,
              ves: _vesFor(p.usd),
              selected: p.key == _selectedKey,
              onTap: () => setState(() => _selectedKey = p.key),
            )),
        const SizedBox(height: AppSpacing.lg),

        // 2. Datos para pagar
        const _StepTitle(2, 'Haz el Pago Móvil a estos datos'),
        const SizedBox(height: AppSpacing.sm),
        _PayeeCard(
          amountUsd: plan.usd,
          amountVes: ves,
          onCopyPhone: () => _copy(_kPmTelefono, 'Teléfono'),
          onCopyDoc: () => _copy(_kPmDocumento, 'Documento'),
          onCopyAmount: ves != null
              ? () => _copy(ves.toStringAsFixed(2), 'Monto en Bs.')
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Reportar
        const _StepTitle(3, 'Reporta tu pago'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _refCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número de referencia *',
            hintText: 'Ej. 004521',
            helperText: 'El número de confirmación que te da tu banco.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de quien paga (opcional)',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono de quien paga (opcional)',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enviar reporte de pago'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Verificamos cada pago manualmente en el banco antes de activar el '
          'plan. Puede tardar unas horas. No compartas datos de tarjetas ni '
          'claves: el Pago Móvil se hace desde tu propio banco.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x2l),
      ],
    );
  }
}

// ── Aviso en móvil ────────────────────────────────────────────────────────────

class _MobileNotice extends StatelessWidget {
  const _MobileNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.computer, size: 44, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'El pago por Pago Móvil está disponible desde la versión de '
              'escritorio o web de la aplicación.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner de estado del último reporte ───────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.request});
  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String text;
    if (request.isApproved) {
      color = AppColors.income;
      icon = Icons.check_circle;
      text = 'Tu último pago fue aprobado. ¡Gracias!';
    } else if (request.isRejected) {
      color = AppColors.expense;
      icon = Icons.cancel;
      text = request.note == null || request.note!.isEmpty
          ? 'Tu último reporte fue rechazado. Verifica los datos y reenvía.'
          : 'Reporte rechazado: ${request.note}';
    } else {
      color = AppColors.warning;
      icon = Icons.hourglass_top;
      text =
          'Tienes un reporte en revisión (ref. ${request.reference}). Te activaremos el plan al confirmarlo.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Título de paso ────────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.number, this.text);
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

// ── Tarjeta de plan seleccionable ─────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.option,
    required this.ves,
    required this.selected,
    required this.onTap,
  });
  final _PlanOption option;
  final double? ves;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textDisabled,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(option.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$ ${_money(option.usd)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (ves != null)
                    Text('Bs. ${_money(ves!)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta con los datos del cobrador ────────────────────────────────────────

class _PayeeCard extends StatelessWidget {
  const _PayeeCard({
    required this.amountUsd,
    required this.amountVes,
    required this.onCopyPhone,
    required this.onCopyDoc,
    required this.onCopyAmount,
  });
  final double amountUsd;
  final double? amountVes;
  final VoidCallback onCopyPhone;
  final VoidCallback onCopyDoc;
  final VoidCallback? onCopyAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _row(context, 'Banco', _kPmBanco),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Teléfono', _kPmTelefono, onCopy: onCopyPhone),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Documento', _kPmDocumento, onCopy: onCopyDoc),
            const Divider(height: AppSpacing.lg),
            _row(context, 'Titular', _kPmTitular),
            const Divider(height: AppSpacing.lg),
            // Monto a pagar
            Row(
              children: [
                const Expanded(
                  child: Text('Monto a pagar',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (amountVes != null)
                      Text('Bs. ${_money(amountVes!)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    Text('\$ ${_money(amountUsd)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                if (onCopyAmount != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copiar monto',
                    onPressed: onCopyAmount,
                  ),
              ],
            ),
            if (amountVes == null) ...[
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'No hay tasa de cambio disponible ahora; se muestra solo el monto en dólares.',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {VoidCallback? onCopy}) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copiar',
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
