import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../providers/subscription_provider.dart';

// ── URLs de checkout LemonSqueezy ─────────────────────────────────────────────

/// Plan Familiar — $2.99/mes (variante mensual existente)
const _kCheckoutFamily =
    'https://ehpd.lemonsqueezy.com/checkout/buy/de15ef1c-ae27-4d9f-b575-1faf290c11db';

/// Plan Familiar Anual — $19.99/año (variante anual existente, reetiquetada)
const _kCheckoutFamilyAnnual =
    'https://ehpd.lemonsqueezy.com/checkout/buy/f101df54-d71f-4466-82f2-d4602fb28147';

/// Plan Premium — $9.99/mes (crear variante en LemonSqueezy cuando se desbloquee VE)
/// TODO: reemplazar con URL real al crear la variante premium en la tienda EHPD.
const _kCheckoutPremium = '';
// 'https://ehpd.lemonsqueezy.com/checkout/buy/PENDING_PREMIUM_VARIANT_UUID';

// ── Página del paywall ────────────────────────────────────────────────────────

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  bool _restoring = false;

  Future<void> _restore() async {
    setState(() => _restoring = true);
    await ref.read(subscriptionProvider.notifier).refresh();
    setState(() => _restoring = false);
    if (!mounted) return;

    final sub = ref.read(subscriptionProvider);
    if (sub.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).planRestored(sub.planLabel))),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).noSubscriptionFound),
        ),
      );
    }
  }

  Future<void> _openCheckout(String baseUrl) async {
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este plan estará disponible muy pronto. '
            'Por ahora puedes adquirir el plan Familiar.',
          ),
        ),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final urlWithUser = userId != null
        ? '$baseUrl?checkout[custom][user_id]=$userId'
        : baseUrl;

    final uri = Uri.parse(urlWithUser);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el navegador.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final ratesAsync = ref.watch(vesRatesProvider);
    final parallelRate = ratesAsync.valueOrNull?.parallel;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).plansPageTitle),
        actions: [
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.of(context).restoreButton),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            const _HeroSection(),
            const SizedBox(height: AppSpacing.xl),

            // ── Plan activo ───────────────────────────────────────────────
            if (sub.isActive) ...[
              _CurrentPlanBanner(state: sub),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Tabla comparativa ─────────────────────────────────────────
            const _FeatureTable(),
            const SizedBox(height: AppSpacing.xl),

            // ── Botones de compra ─────────────────────────────────────────
            if (!sub.isActive) ...[
              _PlanCard(
                title: S.of(context).planFamiliarTitle,
                subtitle: S.of(context).planFamiliarSubtitle,
                price: '\$2.99 / mes',
                priceVes: _toVes(2.99, parallelRate),
                annualPrice: '\$19.99 / año (ahorra 44%)',
                annualPriceVes: _toVes(19.99, parallelRate),
                color: AppColors.primary,
                onTapMonthly: () => _openCheckout(_kCheckoutFamily),
                onTapAnnual: () => _openCheckout(_kCheckoutFamilyAnnual),
              ),
              const SizedBox(height: AppSpacing.md),
              _PlanCard(
                title: S.of(context).planPremiumTitle,
                subtitle: S.of(context).planPremiumSubtitle,
                price: '\$9.99 / mes',
                priceVes: _toVes(9.99, parallelRate),
                annualPrice: null,
                annualPriceVes: null,
                color: AppColors.savings,
                badge: S.of(context).comingSoonBadge,
                onTapMonthly: () => _openCheckout(_kCheckoutPremium),
                onTapAnnual: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (parallelRate != null)
                Text(
                  'Ref. tasa paralela: Bs. ${parallelRate.toStringAsFixed(2)}/\$',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDisabled,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.lg),
              const _CheckoutNote(),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// Convierte USD → VES formateado, o null si no hay tasa disponible.
  static String? _toVes(double usd, double? rate) {
    if (rate == null || rate <= 0) return null;
    final ves = usd * rate;
    return 'Bs. ${NumberFormat('#,##0.00', 'es').format(ves)}';
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          S.of(context).choosePlanTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          S.of(context).choosePlanSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Banner de plan activo ─────────────────────────────────────────────────────

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.state});
  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final expires = state.expiresAt;
    final expiryText = expires != null
        ? 'Vence el ${expires.day}/${expires.month}/${expires.year}'
        : 'Sin fecha de vencimiento';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.income),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan ${state.planLabel} activo',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.income,
                ),
              ),
              Text(
                expiryText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tabla comparativa de features ─────────────────────────────────────────────

typedef _FeatureDef = ({
  String label,
  bool free,
  bool family,
  bool premium,
  String? freeNote,
  String? familyNote,
  String? premiumNote,
});

class _FeatureTable extends StatelessWidget {
  const _FeatureTable();

  static final List<_FeatureDef> _features = [
    (
      label: 'Transacciones ilimitadas',
      free: true, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'Presupuestos y metas',
      free: true, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'Categorías personalizadas',
      free: true, family: true, premium: true,
      freeNote: 'Hasta 10', familyNote: 'Hasta 30', premiumNote: 'Hasta 50',
    ),
    (
      label: 'Miembros del grupo',
      free: true, family: true, premium: true,
      freeNote: 'Hasta 2', familyNote: 'Hasta 5', premiumNote: 'Hasta 10',
    ),
    (
      label: 'Exportar PDF y CSV',
      free: false, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'OCR de comprobantes',
      free: false, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'App de escritorio',
      free: false, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'IA: insights financieros',
      free: false, family: false, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
    (
      label: 'Soporte prioritario',
      free: false, family: true, premium: true,
      freeNote: null, familyNote: null, premiumNote: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                _HeaderCell('Gratis', color: AppColors.textSecondary),
                _HeaderCell('Familiar', color: AppColors.primary),
                _HeaderCell('Premium', color: AppColors.savings),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filas
          ..._features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Column(
              children: [
                _FeatureRow(feature: f),
                if (i < _features.length - 1)
                  const Divider(height: 1, indent: AppSpacing.md),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kColumnWidth,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

const double _kColumnWidth = 68;

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final _FeatureDef feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(feature.label, style: const TextStyle(fontSize: 13)),
          ),
          _Cell(
            enabled: feature.free,
            note: feature.freeNote,
            highlight: false,
          ),
          _Cell(
            enabled: feature.family,
            note: feature.familyNote,
            highlight: true,
            highlightColor: AppColors.primary,
          ),
          _Cell(
            enabled: feature.premium,
            note: feature.premiumNote,
            highlight: true,
            highlightColor: AppColors.savings,
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.enabled,
    this.note,
    required this.highlight,
    this.highlightColor,
  });
  final bool enabled;
  final String? note;
  final bool highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (highlight ? (highlightColor ?? AppColors.primary) : AppColors.textSecondary)
        : AppColors.textDisabled;

    return SizedBox(
      width: _kColumnWidth,
      child: note != null && enabled
          ? Text(
              note!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            )
          : Icon(
              enabled ? Icons.check_rounded : Icons.remove,
              size: 18,
              color: color,
            ),
    );
  }
}

// ── Tarjeta de plan con botones mensual/anual ─────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.priceVes,
    required this.annualPrice,
    this.annualPriceVes,
    required this.color,
    required this.onTapMonthly,
    required this.onTapAnnual,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? priceVes;
  final String? annualPrice;
  final String? annualPriceVes;
  final Color color;
  final VoidCallback onTapMonthly;
  final VoidCallback? onTapAnnual;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Botones
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                FilledButton(
                  onPressed: onTapMonthly,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(price),
                ),
                if (priceVes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '≈ $priceVes / mes',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                if (annualPrice != null && onTapAnnual != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: onTapAnnual,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(annualPrice!),
                  ),
                  if (annualPriceVes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '≈ $annualPriceVes / año',
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nota informativa ──────────────────────────────────────────────────────────

class _CheckoutNote extends StatelessWidget {
  const _CheckoutNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      S.of(context).checkoutNote,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textDisabled,
          ),
      textAlign: TextAlign.center,
    );
  }
}
