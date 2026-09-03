import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/providers/display_prefs_provider.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../data/local/app_database.dart';
import '../../../../router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../family/providers/family_provider.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/ocr_settings_provider.dart';

// ── Helpers de plataforma ─────────────────────────────────────────────────────

bool get _isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

// ── Página principal ──────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _CurrencySection(),
          SizedBox(height: AppSpacing.x2l),
          _OcrSection(),
          SizedBox(height: AppSpacing.x2l),
          _ThemeSection(),
          SizedBox(height: AppSpacing.x2l),
          _SubscriptionSection(),
          SizedBox(height: AppSpacing.x2l),
          _BackupSection(),
          SizedBox(height: AppSpacing.x2l),
          _AboutSection(),
          SizedBox(height: AppSpacing.x2l),
          _AccountSection(),
        ],
      ),
    );
  }
}

// ── Sección Moneda principal ──────────────────────────────────────────────────

class _CurrencySection extends ConsumerWidget {
  const _CurrencySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPrefsProvider);
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.payments_outlined,
          title: s.primaryCurrencyTitle,
          subtitle: s.primaryCurrencySubtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              _CurrencyTile(
                label: 'USD — Dólar',
                code: 'USD',
                selected: prefs.primaryCurrency == 'USD',
                onTap: () => ref
                    .read(displayPrefsProvider.notifier)
                    .setPrimaryCurrency('USD'),
              ),
              const Divider(height: 1, indent: AppSpacing.lg),
              _CurrencyTile(
                label: 'EUR — Euro',
                code: 'EUR',
                selected: prefs.primaryCurrency == 'EUR',
                onTap: () => ref
                    .read(displayPrefsProvider.notifier)
                    .setPrimaryCurrency('EUR'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
          code == 'EUR' ? Icons.euro : Icons.attach_money,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            : null,
        onTap: onTap,
      );
}

// ── Sección OCR ───────────────────────────────────────────────────────────────

class _OcrSection extends ConsumerStatefulWidget {
  const _OcrSection();

  @override
  ConsumerState<_OcrSection> createState() => _OcrSectionState();
}

class _OcrSectionState extends ConsumerState<_OcrSection> {
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _claudeKeyCtrl;
  late TextEditingController _ollamaUrlCtrl;
  late TextEditingController _ollamaModelCtrl;

  bool _obscureGemini = true;
  bool _obscureClaude = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(ocrSettingsProvider);
    _geminiKeyCtrl = TextEditingController(text: s.geminiApiKey);
    _claudeKeyCtrl = TextEditingController(text: s.claudeApiKey);
    _ollamaUrlCtrl = TextEditingController(text: s.ollamaUrl);
    _ollamaModelCtrl = TextEditingController(text: s.ollamaModel);
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    _claudeKeyCtrl.dispose();
    _ollamaUrlCtrl.dispose();
    _ollamaModelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(ocrSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.document_scanner_outlined,
          title: S.of(context).ocrSectionTitle,
          subtitle: S.of(context).ocrSectionSubtitle,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Selector de backend ───────────────────────────────────────────────
        Text(
          S.of(context).ocrEngineLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BackendSelector(
          selected: settings.backend,
          isMobile: _isMobile,
          onChanged: (b) => ref
              .read(ocrSettingsProvider.notifier)
              .update(settings.copyWith(backend: b)),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Campos según backend ──────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (settings.backend) {
            OcrBackend.gemini => _GeminiFields(
                key: const ValueKey('gemini'),
                ctrl: _geminiKeyCtrl,
                obscure: _obscureGemini,
                onToggleObscure: () =>
                    setState(() => _obscureGemini = !_obscureGemini),
              ),
            OcrBackend.claude => _ClaudeFields(
                key: const ValueKey('claude'),
                ctrl: _claudeKeyCtrl,
                obscure: _obscureClaude,
                onToggleObscure: () =>
                    setState(() => _obscureClaude = !_obscureClaude),
              ),
            OcrBackend.ollama => _OllamaFields(
                key: const ValueKey('ollama'),
                urlCtrl: _ollamaUrlCtrl,
                modelCtrl: _ollamaModelCtrl,
                showMobileWarning: _isMobile &&
                    (_ollamaUrlCtrl.text.contains('localhost') ||
                        _ollamaUrlCtrl.text.contains('127.0.0.1')),
              ),
          },
        ),
        const SizedBox(height: AppSpacing.x2l),

        // ── Guardar ───────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(settings),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(S.of(context).saveOcrConfig),
          ),
        ),
      ],
    );
  }

  Future<void> _save(OcrSettings current) async {
    // Advertencia si Ollama + localhost en móvil
    if (_isMobile &&
        current.backend == OcrBackend.ollama &&
        (_ollamaUrlCtrl.text.contains('localhost') ||
            _ollamaUrlCtrl.text.contains('127.0.0.1'))) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.of(context).ollamaWarningTitle),
          content: Text(
            S.of(context).ollamaMobileWarningDialog,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.of(context).fixButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(S.of(context).saveAnywayButton),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    await ref.read(ocrSettingsProvider.notifier).update(
          current.copyWith(
            geminiApiKey: _geminiKeyCtrl.text.trim(),
            claudeApiKey: _claudeKeyCtrl.text.trim(),
            ollamaUrl: _ollamaUrlCtrl.text.trim().isEmpty
                ? 'http://localhost:11434'
                : _ollamaUrlCtrl.text.trim(),
            ollamaModel: _ollamaModelCtrl.text.trim().isEmpty
                ? 'gemma4:31b-cloud'
                : _ollamaModelCtrl.text.trim(),
          ),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).ocrConfigSaved)),
      );
    }
  }
}

// ── Selector de backend ───────────────────────────────────────────────────────

class _BackendSelector extends StatelessWidget {
  const _BackendSelector({
    required this.selected,
    required this.isMobile,
    required this.onChanged,
  });

  final OcrBackend selected;
  final bool isMobile;
  final ValueChanged<OcrBackend> onChanged;

  @override
  Widget build(BuildContext context) {
    final backends = [
      (
        OcrBackend.gemini,
        'Gemini',
        S.of(context).backendGeminiSubtitle,
        Icons.auto_awesome_outlined,
        null, // sin badge
      ),
      (
        OcrBackend.claude,
        'Claude API',
        S.of(context).backendClaudeSubtitle,
        Icons.psychology_outlined,
        null,
      ),
      (
        OcrBackend.ollama,
        'Ollama',
        isMobile ? S.of(context).backendOllamaSubtitleMobile : S.of(context).backendOllamaSubtitleDesktop,
        Icons.computer_outlined,
        isMobile ? S.of(context).backendOllamaBadge : null,
      ),
    ];

    return Column(
      children: backends.map((entry) {
        final (backend, label, subtitle, icon, badge) = entry;
        final isSelected = selected == backend;
        return GestureDetector(
          onTap: () => onChanged(backend),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Campos Gemini ─────────────────────────────────────────────────────────────

class _GeminiFields extends StatelessWidget {
  const _GeminiFields({
    super.key,
    required this.ctrl,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: S.of(context).geminiApiKeyLabel,
              hintText: 'AIza...',
              helperText: S.of(context).geminiKeyHelper,
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoBanner(
            icon: Icons.info_outline,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
            text: S.of(context).geminiFreeTierInfo,
          ),
        ],
      );
}

// ── Campos Claude ─────────────────────────────────────────────────────────────

class _ClaudeFields extends StatelessWidget {
  const _ClaudeFields({
    super.key,
    required this.ctrl,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: S.of(context).claudeApiKeyLabel,
          hintText: 'sk-ant-...',
          helperText: S.of(context).claudeKeyHelper,
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: onToggleObscure,
          ),
        ),
      );
}

// ── Campos Ollama ─────────────────────────────────────────────────────────────

class _OllamaFields extends StatelessWidget {
  const _OllamaFields({
    super.key,
    required this.urlCtrl,
    required this.modelCtrl,
    required this.showMobileWarning,
  });

  final TextEditingController urlCtrl;
  final TextEditingController modelCtrl;
  final bool showMobileWarning;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMobileWarning) ...[
            _InfoBanner(
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
              text: S.of(context).ollamaMobileWarningBanner,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: S.of(context).ollamaUrlLabel,
              hintText: 'http://localhost:11434',
              helperText: S.of(context).ollamaUrlHelper,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: modelCtrl,
            decoration: InputDecoration(
              labelText: S.of(context).modelLabel,
              hintText: 'gemma4:31b-cloud',
              helperText: S.of(context).ollamaModelHelper,
            ),
          ),
        ],
      );
}

// ── Sección Tema ──────────────────────────────────────────────────────────────

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.palette_outlined,
          title: S.of(context).themeTitle,
          subtitle: null,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              _ThemeTile(
                label: S.of(context).themeLight,
                icon: Icons.light_mode_outlined,
                mode: ThemeMode.light,
                selected: current == ThemeMode.light,
                onTap: () => ref.read(themeModeProvider.notifier).set(ThemeMode.light),
              ),
              const Divider(height: 1, indent: AppSpacing.lg),
              _ThemeTile(
                label: S.of(context).themeDark,
                icon: Icons.dark_mode_outlined,
                mode: ThemeMode.dark,
                selected: current == ThemeMode.dark,
                onTap: () => ref.read(themeModeProvider.notifier).set(ThemeMode.dark),
              ),
              const Divider(height: 1, indent: AppSpacing.lg),
              _ThemeTile(
                label: S.of(context).themeSystem,
                icon: Icons.brightness_auto_outlined,
                mode: ThemeMode.system,
                selected: current == ThemeMode.system,
                onTap: () => ref.read(themeModeProvider.notifier).set(ThemeMode.system),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
      dense: true,
    );
  }
}

// ── Sección Plan / Suscripción ───────────────────────────────────────────────

class _SubscriptionSection extends ConsumerWidget {
  const _SubscriptionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).planTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListTile(
            leading: Icon(
              sub.isActive ? Icons.check_circle_rounded : Icons.star_outline,
              color: sub.isActive ? AppColors.income : AppColors.primary,
            ),
            title: Text(S.of(context).planLabelPrefix(sub.planLabel)),
            subtitle: Text(
              sub.isActive ? S.of(context).planActive : S.of(context).planUpgradePrompt,
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onTap: () => context.push(AppRoutes.paywall),
          ),
        ),
      ],
    );
  }
}

// ── Sección Seguridad y Datos ────────────────────────────────────────────────

class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioAvailable = ref.watch(biometricAvailableProvider).valueOrNull ?? false;
    final bioEnabled = ref.watch(biometricEnabledProvider).valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.security_outlined, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              S.of(context).securityTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),

        // ── Biometría ──────────────────────────────────────────────────
        if (bioAvailable) ...[
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
              title: Text(S.of(context).biometricTitle),
              subtitle: Text(
                S.of(context).biometricSubtitle,
              ),
              value: bioEnabled,
              onChanged: (v) =>
                  ref.read(biometricEnabledProvider.notifier).toggle(v),
            ),
          ),
        ],

        // ── Backup ─────────────────────────────────────────────────────
        const SizedBox(height: AppSpacing.md),
        Text(
          S.of(context).backupTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          S.of(context).backupDesc,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bio = ref.read(biometricServiceProvider);
                  final ok = await bio.authenticate(
                    reason: S.of(context).biometricExportReason,
                  );
                  if (!ok || !context.mounted) return;
                  final db = ref.read(appDatabaseProvider);
                  final groupId = ref.read(activeGroupIdProvider);
                  BackupService.exportBackup(
                    context: context,
                    db: db,
                    groupId: groupId,
                  );
                },
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(S.of(context).exportButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bio = ref.read(biometricServiceProvider);
                  final ok = await bio.authenticate(
                    reason: S.of(context).biometricImportReason,
                  );
                  if (!ok || !context.mounted) return;
                  final db = ref.read(appDatabaseProvider);
                  final groupId = ref.read(activeGroupIdProvider);
                  BackupService.importBackup(
                    context: context,
                    db: db,
                    groupId: groupId,
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(S.of(context).importButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Sección Acerca de ─────────────────────────────────────────────────────────

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeStatus = ref.watch(realtimeStatusProvider);

    final (statusText, statusColor) = realtimeStatus.when(
      data: (s) => (s.label, _statusColor(s)),
      loading: () => (S.of(context).statusConnecting, AppColors.textDisabled),
      error: (_, __) => (S.of(context).errorLabel, AppColors.expense),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.info_outline,
          title: S.of(context).aboutTitle,
          subtitle: null,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(S.of(context).versionLabel, '1.0.0'),
                const Divider(height: AppSpacing.x2l),
                _InfoRow(S.of(context).databaseLabel, 'SQLite local (Drift)'),
                const Divider(height: AppSpacing.x2l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).realtimeSyncLabel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(RealtimeStatus s) => switch (s) {
        RealtimeStatus.connected     => AppColors.income,
        RealtimeStatus.connecting    => AppColors.warning,
        RealtimeStatus.reconnecting  => AppColors.warning,
        RealtimeStatus.failed        => AppColors.textDisabled,
        RealtimeStatus.disconnected  => AppColors.textDisabled,
      };
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
}

// ── Sección Cuenta ────────────────────────────────────────────────────────────

class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection();

  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.manage_accounts_outlined,
            title: S.of(context).accountLabel,
            subtitle: null,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBanner(
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.expense,
                    bgColor: AppColors.expenseLight,
                    text: S.of(context).deleteAccountWarning,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense),
                      ),
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.expense,
                              ),
                            )
                          : const Icon(Icons.delete_forever_outlined),
                      label: Text(
                        _deleting ? S.of(context).deletingAccount : S.of(context).deleteAccountButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _confirmDelete() async {
    // Diálogo de confirmación — el usuario debe escribir ELIMINAR
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteConfirmDialog(),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      // 1. Llamar Edge Function y cerrar sesión remota
      await ref.read(authNotifierProvider.notifier).deleteAccount();

      // 2. Limpiar base de datos local
      await ref.read(appDatabaseProvider).clearAllUserData();

      // 3. Limpiar SharedPreferences (caché de suscripción, configuración OCR, etc.)
      await SubscriptionService.instance.clearCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // 4. Navegar al login
      context.go('/auth/login');
    } on AccountDeletionException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);

      // Error manejable: el usuario es admin de un grupo con miembros
      if (e.code == 'owner_with_members') {
        _showError(
          context,
          S.of(context).transferAdminTitle,
          e.message,
        );
      } else {
        _showError(context, S.of(context).errorLabel, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showError(
        context,
        S.of(context).errorUnexpectedTitle,
        S.of(context).deleteAccountFailedMessage,
      );
    }
  }

  void _showError(BuildContext ctx, String title, String message) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(ctx).understoodButton),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo de confirmación con texto ─────────────────────────────────────────

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _ctrl = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final ok = _ctrl.text.trim() == S.of(context).deleteConfirmWord;
      if (ok != _canConfirm) setState(() => _canConfirm = ok);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(S.of(context).deleteAccountConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).deleteAccountIrreversibleBody,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              S.of(context).deleteAccountTypePrompt,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: S.of(context).deleteConfirmWord,
                errorText: _ctrl.text.isNotEmpty && !_canConfirm
                    ? S.of(context).deleteAccountTypeError
                    : null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed:
                _canConfirm ? () => Navigator.of(context).pop(true) : null,
            child: Text(S.of(context).deleteAccountFinalButton),
          ),
        ],
      );
}
