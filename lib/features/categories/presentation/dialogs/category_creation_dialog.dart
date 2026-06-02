import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../data/local/app_database.dart';
import '../../providers/categories_provider.dart';

/// Diálogo de creación de categoría personalizada.
///
/// Retorna [CategoriesTableData] si se creó exitosamente, o null si se canceló.
///
/// No utiliza file pickers → seguro para usar como Dialog en todas las
/// plataformas, incluyendo Windows desktop.
class CategoryCreationDialog extends ConsumerStatefulWidget {
  const CategoryCreationDialog({
    super.key,
    this.initialName = '',
    this.initialType = 'expense',
  });

  final String initialName;
  final String initialType;

  @override
  ConsumerState<CategoryCreationDialog> createState() =>
      _CategoryCreationDialogState();
}

class _CategoryCreationDialogState
    extends ConsumerState<CategoryCreationDialog> {
  late final TextEditingController _nameCtrl;
  late String _type;
  String _iconCode = kIconOptions.first.$1;
  String _colorHex = kColorPalette.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }
    setState(() => _saving = true);
    final cat = await ref.read(categoriesNotifierProvider.notifier).create(
          name: name,
          iconCode: _iconCode,
          colorHex: _colorHex,
          type: _type,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (cat != null) {
      Navigator.of(context).pop(cat);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la categoría. Intenta de nuevo.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nombre ────────────────────────────────────────────────────
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Mascotas, Gimnasio, Farmacia…',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Tipo ──────────────────────────────────────────────────────
              Text('Tipo', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _TypeChip(
                    label: 'Gasto',
                    active: _type == 'expense',
                    color: AppColors.expense,
                    onTap: () => setState(() => _type = 'expense'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TypeChip(
                    label: 'Ingreso',
                    active: _type == 'income',
                    color: AppColors.income,
                    onTap: () => setState(() => _type = 'income'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Ícono ─────────────────────────────────────────────────────
              Text('Ícono', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kIconOptions.map((opt) {
                  final (code, icon) = opt;
                  final selected = _iconCode == code;
                  final accent = colorFromHex(_colorHex);
                  return GestureDetector(
                    onTap: () => setState(() => _iconCode = code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: selected ? accent : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Color ─────────────────────────────────────────────────────
              Text('Color', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kColorPalette.map((hex) {
                  final color = colorFromHex(hex);
                  final selected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorHex = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2.5,
                              )
                            : Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Vista previa ──────────────────────────────────────────────
              _CategoryPreview(
                name: _nameCtrl.text.trim().isEmpty
                    ? 'Vista previa'
                    : _nameCtrl.text.trim(),
                iconCode: _iconCode,
                colorHex: _colorHex,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}

// ── Chip de tipo (Gasto / Ingreso) ────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Vista previa del chip de categoría ───────────────────────────────────────

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({
    required this.name,
    required this.iconCode,
    required this.colorHex,
  });
  final String name;
  final String iconCode;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(colorHex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Así se verá:',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconFromCode(iconCode), size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
