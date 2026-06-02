import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Niveles de alerta ─────────────────────────────────────────────────────────

enum BudgetAlertLevel {
  /// Gasto >= 80 % del límite pero < 100 %
  warning,

  /// Gasto >= 100 % del límite
  over,
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class BudgetAlert {
  const BudgetAlert({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.level,
  });

  final String categoryId;
  final String categoryName;
  final double spent;
  final double limit;
  final BudgetAlertLevel level;

  bool get isOver => level == BudgetAlertLevel.over;

  String get message => isOver
      ? '⚠️ Presupuesto de $categoryName superado '
          '(\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)})'
      : '📊 $categoryName al '
          '${(spent / limit * 100).toStringAsFixed(0)} % del presupuesto '
          '(\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)})';
}

// ── Provider ──────────────────────────────────────────────────────────────────
// Se establece desde TransactionNotifier tras cada gasto.
// AdaptiveScaffold lo escucha y muestra el SnackBar correspondiente.

final budgetAlertProvider = StateProvider<BudgetAlert?>((ref) => null);
