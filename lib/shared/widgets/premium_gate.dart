import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/subscription/presentation/pages/paywall_page.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import '../../l10n/app_localizations.dart';

// ── Nivel mínimo de plan requerido ────────────────────────────────────────────

/// Nivel de plan mínimo para desbloquear un feature.
enum PlanLevel {
  /// Requiere al menos plan Familiar (family, premium, beta).
  family,

  /// Requiere plan Premium o Beta.
  premium,
}

extension PlanLevelX on PlanLevel {
  String get label => switch (this) {
        PlanLevel.family  => 'Familiar',
        PlanLevel.premium => 'Premium',
      };

  bool check(WidgetRef ref) => switch (this) {
        PlanLevel.family  => ref.watch(hasGroupAccessProvider),
        PlanLevel.premium => ref.watch(hasAiAccessProvider),
      };
}

// ── PremiumGate ───────────────────────────────────────────────────────────────

/// Bloquea el acceso a un feature según el nivel de plan requerido.
///
/// - Si el usuario tiene el plan requerido: renderiza [child] directamente.
/// - Si no: renderiza [lockedChild] o un widget de cerrojo genérico.
///
/// ```dart
/// PremiumGate(
///   featureLabel: 'Exportar PDF/CSV',
///   child: ExportButton(),
/// )
///
/// PremiumGate(
///   featureLabel: 'IA Insights',
///   requiredLevel: PlanLevel.premium,
///   child: InsightsWidget(),
/// )
/// ```
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.child,
    this.featureLabel,
    this.lockedChild,
    this.mode = PremiumGateMode.overlay,
    this.requiredLevel = PlanLevel.family,
  });

  /// Widget a mostrar cuando el usuario tiene el plan requerido.
  final Widget child;

  /// Nombre del feature bloqueado (se muestra en el tooltip / overlay).
  final String? featureLabel;

  /// Widget alternativo a mostrar cuando el feature está bloqueado.
  final Widget? lockedChild;

  /// Cómo presentar el bloqueo.
  final PremiumGateMode mode;

  /// Plan mínimo necesario. Por defecto [PlanLevel.family].
  final PlanLevel requiredLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = requiredLevel.check(ref);
    if (hasAccess) return child;

    if (lockedChild != null) {
      return GestureDetector(
        onTap: () => _openPaywall(context),
        child: lockedChild,
      );
    }

    return switch (mode) {
      PremiumGateMode.overlay => _LockedOverlay(
          featureLabel: featureLabel,
          planLabel: requiredLevel.label,
          onUpgrade: () => _openPaywall(context),
        ),
      PremiumGateMode.icon => _LockedIcon(
          planLabel: requiredLevel.label,
          onUpgrade: () => _openPaywall(context),
        ),
      PremiumGateMode.silent => const SizedBox.shrink(),
    };
  }

  static void _openPaywall(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
  }
}

// ── PremiumTapGate ────────────────────────────────────────────────────────────

/// Intercepta un toque y abre el paywall si el usuario no tiene el plan.
class PremiumTapGate extends ConsumerWidget {
  const PremiumTapGate({
    super.key,
    required this.child,
    this.onAllowed,
    this.requiredLevel = PlanLevel.family,
  });

  final Widget child;

  /// Callback ejecutado cuando el usuario tiene acceso.
  final VoidCallback? onAllowed;

  /// Plan mínimo necesario.
  final PlanLevel requiredLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = requiredLevel.check(ref);

    if (hasAccess) {
      if (onAllowed != null) {
        return GestureDetector(onTap: onAllowed, child: child);
      }
      return child;
    }

    return GestureDetector(
      onTap: () => PremiumGate._openPaywall(context),
      child: Stack(
        children: [
          IgnorePointer(child: child),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modos de presentación ─────────────────────────────────────────────────────

enum PremiumGateMode {
  /// Muestra un recuadro con candado e ícono de upgrade.
  overlay,

  /// Muestra solo un ícono de candado pequeño.
  icon,

  /// No renderiza nada cuando está bloqueado.
  silent,
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({
    this.featureLabel,
    required this.planLabel,
    required this.onUpgrade,
  });

  final String? featureLabel;
  final String planLabel;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUpgrade,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                featureLabel != null
                    ? S.of(context).gateOnlyInPlan(featureLabel!, planLabel)
                    : S.of(context).gateAvailableInPlan(planLabel),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedIcon extends StatelessWidget {
  const _LockedIcon({required this.planLabel, required this.onUpgrade});
  final String planLabel;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.lock_outline_rounded),
      color: AppColors.textDisabled,
      tooltip: S.of(context).gateAvailableInPlan(planLabel),
      onPressed: onUpgrade,
    );
  }
}
