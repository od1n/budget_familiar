import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  Future<void> _markDone(WidgetRef ref) async {
    ref.read(onboardingDoneProvider.notifier).state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3l,
                  vertical: AppSpacing.x4l,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3l),
                  Text(
                    S.of(context).appTitle,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    S.of(context).onboardingTagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.x5l),
                  _FeatureRow(
                    icon: Icons.sync_alt_rounded,
                    label: S.of(context).onboardingSync,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FeatureRow(
                    icon: Icons.trending_up_rounded,
                    label: S.of(context).onboardingBudgets,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FeatureRow(
                    icon: Icons.currency_exchange_rounded,
                    label: S.of(context).onboardingRates,
                  ),
                  const SizedBox(height: AppSpacing.x5l),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await _markDone(ref);
                        if (context.mounted) context.go(AppRoutes.register);
                      },
                      child: Text(S.of(context).onboardingCreateAccount),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _markDone(ref);
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                      child: Text(S.of(context).onboardingHasAccount),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
