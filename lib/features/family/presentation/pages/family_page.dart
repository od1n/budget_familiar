import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/deeplink_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../data/local/app_database.dart';
import '../../../../router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../categories/presentation/dialogs/category_creation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../categories/providers/categories_provider.dart';
import '../../../../core/services/referral_service.dart';
import '../../providers/family_provider.dart';

class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).familyPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ── Perfil ────────────────────────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: AppSpacing.lg),

          // ── Grupo familiar ────────────────────────────────────────────────
          Text(
            S.of(context).familyGroupSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FamilyGroupCard(userId: user?.id ?? ''),
          const SizedBox(height: AppSpacing.lg),

          // ── Referidos ───────────────────────────────────────────────────────
          Text(
            S.of(context).referralsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReferralCard(),
          const SizedBox(height: AppSpacing.lg),

          // ── Categorías personalizadas ─────────────────────────────────────
          Text(
            S.of(context).customCategoriesSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CustomCategoriesCard(
            onAdd: () => _openCreateDialog(context, ref),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Ajustes ───────────────────────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
              title: Text(S.of(context).appSettingsTitle),
              subtitle: Text(S.of(context).appSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Cuenta ────────────────────────────────────────────────────────
          Text(S.of(context).accountLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.expense),
              title: Text(
                S.of(context).signOutLabel,
                style: const TextStyle(color: AppColors.expense),
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(S.of(context).signOutLabel),
                    content: Text(
                      S.of(context).signOutConfirm,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, false),
                        child: Text(S.of(context).cancelButton),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, true),
                        child: Text(
                          S.of(context).signOutLabel,
                          style: const TextStyle(color: AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .signOut();
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.x5l),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<CategoriesTableData>(
      context: context,
      builder: (_) => const CategoryCreationDialog(),
    );
    // El stream customCategoriesProvider se actualiza automáticamente.
  }
}

// ── Tarjeta de grupo familiar ─────────────────────────────────────────────────

class _FamilyGroupCard extends ConsumerWidget {
  const _FamilyGroupCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(activeGroupProvider);
    final activeGroupId = ref.watch(activeGroupIdProvider);
    final isPersonal = activeGroupId == userId || activeGroupId.isEmpty;

    return groupAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(S.of(context).errorGenericDetail(e.toString())),
        ),
      ),
      data: (group) {
        if (isPersonal || group == null) {
          return _NoGroupCard(userId: userId);
        }
        return _ActiveGroupCard(group: group, userId: userId);
      },
    );
  }
}

// ── Sin grupo ─────────────────────────────────────────────────────────────────

class _NoGroupCard extends ConsumerStatefulWidget {
  const _NoGroupCard({required this.userId});
  final String userId;

  @override
  ConsumerState<_NoGroupCard> createState() => _NoGroupCardState();
}

class _NoGroupCardState extends ConsumerState<_NoGroupCard> {
  @override
  void initState() {
    super.initState();
    // Procesar deeplink pendiente (si la app se abrió con un link de invitación).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = ref.read(deeplinkServiceProvider).consumePendingCode();
      if (code != null && mounted) {
        _joinWithCode(code);
      }
    });
  }

  Future<void> _joinWithCode(String code) async {
    try {
      final groupResult =
          await ref.read(familyServiceProvider).joinGroupByCode(code);
      await ref
          .read(activeGroupIdProvider.notifier)
          .setGroup(groupResult.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).joinedGroup(groupResult.group.name)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorJoin(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar deeplinks mientras esta pantalla está visible.
    ref.listen(
      pendingInviteCodeProvider,
      (_, next) {
        final code = next.valueOrNull;
        if (code != null) {
          ref.read(deeplinkServiceProvider).consumePendingCode();
          _joinWithCode(code);
        }
      },
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).individualMode,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              S.of(context).individualModeDesc,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(S.of(context).createFamilyGroup),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                // Unirse a un grupo NO requiere plan de pago: el servidor
                // (join_group_by_invite) solo valida el límite de miembros del
                // grupo, que depende del plan del DUEÑO. Modelo familiar estándar.
                onPressed: () => _showJoinDialog(context, ref),
                icon: const Icon(Icons.link, size: 18),
                label: Text(S.of(context).joinWithCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).createGroupTitle),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: S.of(context).groupNameLabel,
            hintText: S.of(context).groupNameHint,
          ),
          autofocus: true,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(dialogContext, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(context).cancelButton),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: Text(S.of(context).createButton),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final groupResult =
          await ref.read(familyServiceProvider).createGroup(result);
      await ref
          .read(activeGroupIdProvider.notifier)
          .setGroup(groupResult.group.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).groupCreated(groupResult.group.name)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorCreateGroup(e.toString()))),
        );
      }
    }
  }

  Future<void> _showJoinDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).joinGroupTitle),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 12, // los invite_code son de 12 caracteres (migración 009)
          decoration: InputDecoration(
            labelText: S.of(context).inviteCodeLabel,
            hintText: S.of(context).inviteCodeHint,
            counterText: '',
          ),
          autofocus: true,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(dialogContext, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(context).cancelButton),
          ),
          FilledButton(
            onPressed: () {
              final code = ctrl.text.trim();
              if (code.isNotEmpty) Navigator.pop(dialogContext, code);
            },
            child: Text(S.of(context).joinButton),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final groupResult =
          await ref.read(familyServiceProvider).joinGroupByCode(result);
      await ref
          .read(activeGroupIdProvider.notifier)
          .setGroup(groupResult.group.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).joinedGroup(groupResult.group.name)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorJoin(e.toString()))),
        );
      }
    }
  }
}

// ── Grupo activo ──────────────────────────────────────────────────────────────

class _ActiveGroupCard extends ConsumerWidget {
  const _ActiveGroupCard({required this.group, required this.userId});
  final FamilyGroupsTableData group;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider);
    final isOwner = group.ownerId == userId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre del grupo ───────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Código de invitación ───────────────────────────────────────
            if (isOwner) ...[
              Text(
                S.of(context).inviteCodeSection,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: group.inviteCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.of(context).codeCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.inviteCode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.copy_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final link = buildInviteLink(group.inviteCode);
                    // ignore: deprecated_member_use
                    Share.share(
                      S.of(context).shareInviteMessage(
                        group.name,
                        group.inviteCode,
                        link,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(S.of(context).shareInviteTooltip),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Miembros ───────────────────────────────────────────────────
            membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(
                S.of(context).errorLoadMembers(e.toString()),
                style: const TextStyle(color: AppColors.expense, fontSize: 12),
              ),
              data: (members) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        S.of(context).membersLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: members.length >= 5
                              ? AppColors.warningLight
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${members.length}/5',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: members.length >= 5
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...members.map(
                    (m) => _MemberTile(
                      member: m,
                      isCurrentUser: m.userId == userId,
                    ),
                  ),
                  if (members.length >= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        S.of(context).groupFull,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Botones owner / miembro ────────────────────────────────────
            if (isOwner)
              membersAsync.maybeWhen(
                data: (members) {
                  final otherMembers =
                      members.where((m) => m.userId != userId).toList();
                  return Column(
                    children: [
                      if (otherMembers.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _transferOwnership(
                              context,
                              ref,
                              otherMembers,
                            ),
                            icon: const Icon(
                              Icons.swap_horiz,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(S.of(context).transferAdminButton),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLeave(context, ref),
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.expense,
                ),
                label: Text(
                  S.of(context).leaveGroupButton,
                  style: const TextStyle(color: AppColors.expense),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.expense),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transferOwnership(
    BuildContext context,
    WidgetRef ref,
    List<GroupMembersTableData> candidates,
  ) async {
    GroupMembersTableData? selected;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(S.of(context).transferAdminTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).transferAdminPrompt,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              RadioGroup<GroupMembersTableData>(
                groupValue: selected,
                onChanged: (v) => setInner(() => selected = v),
                child: Column(
                  children: candidates
                      .map(
                        (m) => RadioListTile<GroupMembersTableData>(
                          value: m,
                          title: Text(
                            m.displayName ??
                                m.email ??
                                m.userId.substring(0, 8),
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                          subtitle: m.email != null && m.displayName != null
                              ? Text(m.email!)
                              : null,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(S.of(context).cancelButton),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(S.of(context).transferAdminButton),
            ),
          ],
        ),
      ),
    );

    if (ok != true || selected == null || !context.mounted) return;

    try {
      await ref
          .read(familyServiceProvider)
          .transferOwnership(group.id, selected!.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).adminTransferred(
                selected!.displayName ?? selected!.email ?? S.of(context).newAdminFallback,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorTransfer(e.toString()))),
        );
      }
    }
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final isOwner = group.ownerId == userId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).leaveGroupTitle),
        content: Text(
          isOwner
              ? S.of(context).leaveGroupAdminWarning
              : S.of(context).leaveGroupConfirmNamed(group.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              S.of(context).leaveGroupButton,
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(familyServiceProvider).leaveGroup(group.id);
      await ref.read(activeGroupIdProvider.notifier).resetToPersonal();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).leftGroup)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorGenericDetail(e.toString()))),
        );
      }
    }
  }
}

// ── Tile de miembro ───────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isCurrentUser});
  final GroupMembersTableData member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final display = member.displayName ??
        member.email ??
        member.userId.substring(0, 8);
    final initial = display.isNotEmpty ? display[0].toUpperCase() : '?';
    final isOwner = member.role == 'owner';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? S.of(context).youSuffix(display) : display,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (member.email != null && member.displayName != null)
                  Text(
                    member.email!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                S.of(context).adminBadge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tarjeta de categorías personalizadas ─────────────────────────────────────

class _CustomCategoriesCard extends ConsumerWidget {
  const _CustomCategoriesCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(customCategoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción
            Text(
              S.of(context).customCategoriesDesc,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            // Lista de categorías
            asyncCats.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                S.of(context).errorGenericDetail(e.toString()),
                style: const TextStyle(color: AppColors.expense),
              ),
              data: (cats) {
                if (cats.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(
                      S.of(context).noCustomCategories,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDisabled,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  );
                }
                return Column(
                  children: cats
                      .map(
                        (cat) => _CustomCategoryTile(
                          cat: cat,
                          onDelete: () =>
                              _confirmDelete(context, ref, cat),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Botón de añadir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(S.of(context).newCategoryButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData cat,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).deleteCategoryTitle),
        content: Text(
          S.of(context).hideCategoryWarning(categoryDisplayName(context, cat.id, cat.name)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.of(context).deleteButton,
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(categoriesNotifierProvider.notifier).delete(cat.id);
    }
  }
}

// ── Tile de categoría personalizada ──────────────────────────────────────────

class _CustomCategoryTile extends StatelessWidget {
  const _CustomCategoryTile({required this.cat, required this.onDelete});
  final CategoriesTableData cat;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(cat.colorHex);
    final isExpense = cat.type == 'expense';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconFromCode(cat.iconCode), size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryDisplayName(context, cat.id, cat.name),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  isExpense ? S.of(context).expenseTypeButton : S.of(context).incomeTypeButton,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isExpense
                            ? AppColors.expense
                            : AppColors.income,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textDisabled,
              size: 18,
            ),
            tooltip: S.of(context).deleteCategoryTitle,
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de referidos ─────────────────────────────────────────────────────

class _ReferralCard extends ConsumerWidget {
  const _ReferralCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(referralCountProvider);
    final earnedAsync = ref.watch(hasEarnedFreeMonthProvider);
    final service = ref.read(referralServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).referralInviteTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        S.of(context).referralInviteBody(service.requiredReferrals),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress
            countAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) {
                final progress =
                    (count / service.requiredReferrals).clamp(0.0, 1.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).referralProgress(count, service.requiredReferrals),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (count >= service.requiredReferrals)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              S.of(context).goalReached,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.income,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          count >= service.requiredReferrals
                              ? AppColors.income
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Redeem button
            earnedAsync.maybeWhen(
              data: (earned) {
                if (!earned) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final ok = await service.redeemFreeMonth();
                        if (ok && context.mounted) {
                          ref.invalidate(referralCountProvider);
                          ref.invalidate(hasEarnedFreeMonthProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                S.of(context).freeMonthActivated,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.redeem, size: 18),
                      label: Text(S.of(context).redeemFreeMonth),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.sm),
            Text(
              // TODO: wire actual referral tracking server-side
              S.of(context).referralTrackingNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de perfil editable ────────────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        user?.userMetadata?['full_name'] as String? ?? 'Usuario';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Card(
      child: InkWell(
        onTap: () => _editName(context, ref, displayName),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).editNameTitle),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: S.of(context).fullNameLabel),
          autofocus: true,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).cancelButton),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: Text(S.of(context).saveButton),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(authNotifierProvider.notifier).updateDisplayName(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).nameUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorUpdate(e.toString()))),
        );
      }
    }
  }
}

