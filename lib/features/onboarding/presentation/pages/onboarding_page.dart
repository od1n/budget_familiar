import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _totalPages = 3;

  Future<void> _markDone() async {
    ref.read(onboardingDoneProvider.notifier).state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() async {
    await _markDone();
    if (mounted) context.go(AppRoutes.register);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.screenPadding,
                ),
                child: isLastPage
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: _skip,
                        child: Text(
                          s.onboardingSkip,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),

            // ── PageView ─────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingStep(
                    icon: Icons.account_balance_wallet_outlined,
                    title: s.appTitle,
                    subtitle:
                        s.onboardingSubtitle1,
                    features: [
                      _FeatureItem(
                        icon: Icons.currency_exchange_rounded,
                        text: s.onboardingRates,
                      ),
                      _FeatureItem(
                        icon: Icons.attach_money_rounded,
                        text: s.onboardingFeature1b,
                      ),
                    ],
                  ),
                  _OnboardingStep(
                    icon: Icons.people_alt_outlined,
                    title: s.onboardingTitle2,
                    subtitle:
                        s.onboardingSubtitle2,
                    features: [
                      _FeatureItem(
                        icon: Icons.sync_alt_rounded,
                        text: s.onboardingSync,
                      ),
                      _FeatureItem(
                        icon: Icons.trending_up_rounded,
                        text: s.onboardingBudgets,
                      ),
                    ],
                  ),
                  _OnboardingStep(
                    icon: Icons.auto_awesome_outlined,
                    title: s.onboardingTitle3,
                    subtitle:
                        s.onboardingSubtitle3,
                    features: [
                      _FeatureItem(
                        icon: Icons.insights_rounded,
                        text: s.onboardingFeature3a,
                      ),
                      _FeatureItem(
                        icon: Icons.receipt_long_outlined,
                        text: s.onboardingFeature3b,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Page indicator dots ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom buttons ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3l,
              ),
              child: isLastPage
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              await _markDone();
                              if (mounted) context.go(AppRoutes.register);
                            },
                            child: Text(s.onboardingCreateAccount),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await _markDone();
                              if (mounted) context.go(AppRoutes.login);
                            },
                            child: Text(s.onboardingHasAccount),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nextPage,
                        child: Text(s.nextButton),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.x4l),
          ],
        ),
      ),
    );
  }
}

// ── Single onboarding step ──────────────────────────────────────────────────

class _FeatureItem {
  const _FeatureItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<_FeatureItem> features;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3l,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.x3l),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3l),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.x5l),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _FeatureRow(icon: f.icon, label: f.text),
                  ),
                ),
              ],
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
