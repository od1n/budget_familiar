import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      data: (user) {
        // Si el usuario existe pero no tiene sesión activa es porque
        // Supabase requiere confirmación de email.
        if (user != null && user.emailConfirmedAt == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: Text(S.of(context).confirmEmailTitle),
              content: Text(
                S.of(context).confirmEmailBody(user.email ?? ''),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go(AppRoutes.login);
                  },
                  child: Text(S.of(context).understoodButton),
                ),
              ],
            ),
          );
        }
        // Si user.confirmedAt != null el router redirige solo al dashboard.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          final msg = e.toString().toLowerCase();
          final l = S.of(context);
          String friendly;
          if (msg.contains('already registered') ||
              msg.contains('already exists')) {
            friendly = l.errorAlreadyRegistered;
          } else if (msg.contains('weak password')) {
            friendly = l.errorWeakPassword;
          } else if (msg.contains('invalid email')) {
            friendly = l.errorInvalidEmail;
          } else {
            friendly = l.errorCreateAccount;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendly),
              backgroundColor: AppColors.expense,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.of(context).createAccountTitle),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).welcomeTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      S.of(context).createAccountSubtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: S.of(context).fullNameLabel,
                        prefixIcon: const Icon(Icons.person_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? S.of(context).nameValidationEmpty
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: S.of(context).emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return S.of(context).emailValidationEmpty;
                        if (!v.contains('@')) return S.of(context).emailValidationInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: S.of(context).passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        helperText: S.of(context).passwordValidationMin(8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).passwordValidationEmpty;
                        }
                        if (v.length < 8) return S.of(context).passwordValidationMin(8);
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2l),
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _register,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(S.of(context).createAccountButton),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${S.of(context).hasAccountPrompt} ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: Text(S.of(context).signInLink),
                          ),
                        ],
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
