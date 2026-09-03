import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/exchange_rate_service.dart'
    show vesRatesProvider;
import '../../../../core/services/supabase_service.dart';
import '../../../../data/local/app_database.dart';
import '../../../family/providers/family_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Abre el diálogo de transferencia interna entre miembros del grupo.
Future<void> openTransferForm(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _TransferFormDialog(),
  );
}

// ── Diálogo principal ─────────────────────────────────────────────────────────

class _TransferFormDialog extends ConsumerStatefulWidget {
  const _TransferFormDialog();

  @override
  ConsumerState<_TransferFormDialog> createState() =>
      _TransferFormDialogState();
}

class _TransferFormDialogState extends ConsumerState<_TransferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _currencyCode = 'USD';
  DateTime _date = DateTime.now();
  GroupMembersTableData? _receiver;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  GroupMembersTableData? _currentMember(List<GroupMembersTableData> members) {
    final uid = supabase.auth.currentUser?.id;
    return members.where((m) => m.userId == uid).firstOrNull;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(S.of(context).internalTransferTitle),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: membersAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(S.of(context).errorGenericDetail(e.toString())),
          data: (members) {
            final me = _currentMember(members);
            final others = members
                .where((m) => m.userId != me?.userId)
                .toList();

            if (me == null) {
              return Text(
                S.of(context).profileNotFoundError,
              );
            }
            if (others.isEmpty) {
              return Text(
                S.of(context).needAnotherMemberError,
              );
            }

            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emisor (sólo lectura)
                  const _SectionLabel('De'),
                  const SizedBox(height: AppSpacing.xs),
                  _MemberChip(
                    name: me.displayName ?? me.email ?? S.of(context).youLabel,
                    isMe: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Receptor
                  const _SectionLabel('Para'),
                  const SizedBox(height: AppSpacing.xs),
                  _ReceiverSelector(
                    members: others,
                    selected: _receiver,
                    onChanged: (m) => setState(() => _receiver = m),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Monto + moneda
                  const _SectionLabel('Monto'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      // Toggle moneda
                      _CurrencyToggle(
                        value: _currencyCode,
                        onChanged: (c) => setState(() => _currencyCode = c),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            isDense: true,
                          ),
                          validator: (v) {
                            final parsed = double.tryParse(
                              v?.replaceAll(',', '.') ?? '',
                            );
                            if (parsed == null || parsed <= 0) {
                              return S.of(context).enterValidAmount;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Fecha
                  const _SectionLabel('Fecha'),
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            DateFormat('d MMM yyyy', 'es').format(_date),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Descripción (opcional)
                  _SectionLabel(S.of(context).descriptionOptionalLabel),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      hintText: S.of(context).transferDescHint,
                      isDense: true,
                    ),
                    maxLength: 120,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(S.of(context).cancelButton),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _submit(context),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz, size: 18),
          label: Text(S.of(context).registerButton),
        ),
      ],
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_receiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).selectReceiverError)),
      );
      return;
    }

    setState(() => _saving = true);

    final amount =
        double.parse(_amountCtrl.text.replaceAll(',', '.'));

    // Calcular equivalente USD si la moneda es VES (tasa paralela)
    double? amountUsdEquivalent;
    if (_currencyCode == 'VES') {
      final rates = ref.read(vesRatesProvider).valueOrNull;
      if (rates != null && rates.parallel > 0) {
        amountUsdEquivalent = amount / rates.parallel;
      }
    }

    final members = ref.read(groupMembersProvider).valueOrNull ?? [];
    final me = _currentMember(members);
    if (me == null) {
      setState(() => _saving = false);
      return;
    }

    // Capturar referencias al contexto ANTES del gap asíncrono
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final receiverName =
        _receiver!.displayName ?? _receiver!.email ?? S.of(context).theMemberFallback;

    final ok = await ref.read(transferNotifierProvider.notifier).create(
          senderMember: me,
          receiverMember: _receiver!,
          amount: amount,
          currencyCode: _currencyCode,
          amountUsdEquivalent: amountUsdEquivalent,
          date: _date,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.of(context).transferRegistered(receiverName)),
        ),
      );
    } else {
      final err = ref.read(transferNotifierProvider).error;
      messenger.showSnackBar(
        SnackBar(content: Text(S.of(context).errorGenericDetail(err.toString()))),
      );
    }
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      );
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.name, this.isMe = false});
  final String name;
  final bool isMe;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              isMe ? S.of(context).youSuffix(name) : name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
}

class _ReceiverSelector extends StatelessWidget {
  const _ReceiverSelector({
    required this.members,
    required this.selected,
    required this.onChanged,
  });
  final List<GroupMembersTableData> members;
  final GroupMembersTableData? selected;
  final ValueChanged<GroupMembersTableData> onChanged;

  @override
  Widget build(BuildContext context) {
    if (members.length == 1) {
      // Si sólo hay un otro miembro, lo seleccionamos automáticamente la 1.ª vez
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (selected == null) onChanged(members.first);
      });
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: members.map((m) {
        final name = m.displayName ?? m.email ?? S.of(context).memberLabel;
        final isSelected = selected?.userId == m.userId;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 15,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const currencies = ['USD', 'VES'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: currencies.map((c) {
        final active = value == c;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                c == currencies.first ? 8 : 0,
              ).copyWith(
                topRight: c == currencies.last
                    ? const Radius.circular(8)
                    : Radius.zero,
                bottomRight: c == currencies.last
                    ? const Radius.circular(8)
                    : Radius.zero,
                topLeft: c == currencies.first
                    ? const Radius.circular(8)
                    : Radius.zero,
                bottomLeft: c == currencies.first
                    ? const Radius.circular(8)
                    : Radius.zero,
              ),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.normal,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Función auxiliar pública para parsear notes JSON ────────────────────────

/// Devuelve los metadatos de una transferencia del campo `notes`.
/// Retorna `null` si no es una transferencia o el JSON está malformado.
TransferMeta? parseTransferMeta(String? notes) {
  if (notes == null) return null;
  try {
    final map = jsonDecode(notes) as Map<String, dynamic>;
    final direction = map['direction'] as String?;
    if (direction == null) return null;
    return TransferMeta(
      direction: direction,
      peerName: map['peer_name'] as String? ?? 'Miembro',
      peerUserId: map['peer_user_id'] as String? ?? '',
    );
  } catch (_) {
    return null;
  }
}

class TransferMeta {
  const TransferMeta({
    required this.direction,
    required this.peerName,
    required this.peerUserId,
  });

  /// 'in' o 'out'
  final String direction;
  final String peerName;
  final String peerUserId;

  bool get isOutgoing => direction == 'out';
}
