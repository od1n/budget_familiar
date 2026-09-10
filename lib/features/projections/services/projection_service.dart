import '../../../core/services/exchange_rate_service.dart';
import '../../../core/services/recurring_service.dart';
import '../../../data/local/app_database.dart';

/// Convierte un monto de cualquier moneda soportada a su equivalente en USD,
/// usando exactamente la misma lógica que el registro de transacciones. Devuelve
/// `null` cuando falta la tasa necesaria, para no falsear la proyección con un
/// valor inventado.
double? amountToUsd(double amount, String currencyCode, VesRates? rates) {
  switch (currencyCode) {
    case 'USD':
      return amount;
    case 'EUR':
      final r = rates?.usdPerEur ?? 0;
      return r > 0 ? amount * r : null;
    case 'MXN':
      final r = rates?.usdMxn ?? 0;
      return r > 0 ? amount / r : null;
    case 'ARS':
      final blue = rates?.usdArsBlue ?? 0;
      final r = blue > 0 ? blue : (rates?.usdArsOficial ?? 0);
      return r > 0 ? amount / r : null;
    default: // VES u otra moneda cotizada en bolívares.
      final r = rates?.parallel ?? 0;
      return r > 0 ? amount / r : null;
  }
}

/// Un mes proyectado: ingresos, gastos (con el colchón variable incluido) y el
/// saldo acumulado al final del mes. Todos los montos en USD.
class ProjectionPoint {
  const ProjectionPoint({
    required this.month,
    required this.incomeUsd,
    required this.expenseUsd,
    required this.balanceUsd,
  });

  /// Primer día del mes proyectado.
  final DateTime month;
  final double incomeUsd;

  /// Incluye los gastos programados de ese mes más el colchón de gasto variable.
  final double expenseUsd;

  /// Saldo acumulado proyectado al final del mes.
  final double balanceUsd;

  double get netUsd => incomeUsd - expenseUsd;
}

/// Resultado completo de una proyección de saldo.
class ProjectionResult {
  const ProjectionResult({
    required this.startingBalanceUsd,
    required this.variableMonthlyExpenseUsd,
    required this.recurringMonthlyIncomeUsd,
    required this.recurringMonthlyExpenseUsd,
    required this.points,
    required this.hasMissingRate,
  });

  /// Saldo del que parte la proyección (neto histórico acumulado, en USD).
  final double startingBalanceUsd;

  /// Estimación mensual de gasto variable (lo que gastas por encima de lo
  /// programado), en USD.
  final double variableMonthlyExpenseUsd;

  /// Ingreso recurrente normalizado a mensual (referencia), en USD.
  final double recurringMonthlyIncomeUsd;

  /// Gasto recurrente normalizado a mensual (referencia), en USD.
  final double recurringMonthlyExpenseUsd;

  final List<ProjectionPoint> points;

  /// `true` si alguna plantilla no se pudo convertir a USD por falta de tasa.
  final bool hasMissingRate;

  double get endingBalanceUsd =>
      points.isEmpty ? startingBalanceUsd : points.last.balanceUsd;

  /// Índice del primer mes en que el saldo proyectado se vuelve negativo, o
  /// `null` si nunca ocurre dentro del horizonte.
  int? get firstNegativeMonthIndex {
    for (var i = 0; i < points.length; i++) {
      if (points[i].balanceUsd < 0) return i;
    }
    return null;
  }

  static const empty = ProjectionResult(
    startingBalanceUsd: 0,
    variableMonthlyExpenseUsd: 0,
    recurringMonthlyIncomeUsd: 0,
    recurringMonthlyExpenseUsd: 0,
    points: [],
    hasMissingRate: false,
  );
}

/// Cálculo de la proyección de saldo. Función pura: no toca base de datos ni red.
class ProjectionService {
  /// Normaliza el monto de una plantilla a su equivalente mensual, para estimar
  /// la porción recurrente del ingreso/gasto (usada solo como referencia y para
  /// derivar el colchón de gasto variable).
  static double monthlyNormalized(double amount, String frequency) =>
      switch (frequency) {
        'daily' => amount * 30,
        'weekly' => amount * 52 / 12,
        'biweekly' => amount * 26 / 12,
        'monthly' => amount,
        'yearly' => amount / 12,
        _ => amount,
      };

  /// Proyecta el saldo mes a mes durante [horizonMonths] meses, empezando el
  /// mes siguiente al actual.
  ///
  /// Modelo: por cada mes, ingresos = ocurrencias reales de las plantillas de
  /// ingreso; gastos = ocurrencias reales de las plantillas de gasto MÁS un
  /// colchón de gasto variable. El colchón evita el doble conteo: es el
  /// promedio de gasto mensual reciente menos la porción ya explicada por las
  /// plantillas recurrentes (nunca negativo).
  static ProjectionResult compute({
    required double startingBalanceUsd,
    required List<RecurringTransactionsTableData> templates,
    required double avgTotalMonthlyExpenseUsd,
    required int horizonMonths,
    required VesRates? rates,
    DateTime? now,
  }) {
    if (horizonMonths <= 0) return ProjectionResult.empty;

    final today = now ?? DateTime.now();
    // Los meses proyectados empiezan el primer día del mes siguiente.
    final firstMonth = DateTime(today.year, today.month + 1, 1);
    final horizonEnd =
        DateTime(firstMonth.year, firstMonth.month + horizonMonths, 1);

    var hasMissingRate = false;
    double recurringMonthlyIncome = 0;
    double recurringMonthlyExpense = 0;

    final incomeByMonth = List<double>.filled(horizonMonths, 0);
    final expenseByMonth = List<double>.filled(horizonMonths, 0);

    for (final t in templates) {
      final usd = amountToUsd(t.amount, t.currencyCode, rates);
      if (usd == null) {
        hasMissingRate = true;
        continue;
      }

      // Porción recurrente mensual (referencia y base del colchón variable).
      final norm = monthlyNormalized(usd, t.frequency);
      if (t.type == 'income') {
        recurringMonthlyIncome += norm;
      } else {
        recurringMonthlyExpense += norm;
      }

      // Distribuye las ocurrencias reales en los meses del horizonte.
      var due = t.nextDueDate;
      var safety = 0;
      while (due.isBefore(horizonEnd) && safety < 2000) {
        // Ocurrencias que quedan de aquí a fin del mes actual se cuentan en el
        // primer mes proyectado.
        final idx = due.isBefore(firstMonth)
            ? 0
            : (due.year - firstMonth.year) * 12 +
                (due.month - firstMonth.month);
        if (idx >= 0 && idx < horizonMonths) {
          if (t.type == 'income') {
            incomeByMonth[idx] += usd;
          } else {
            expenseByMonth[idx] += usd;
          }
        }
        due = RecurringService.advanceDate(due, t.frequency, t.dayOfMonth);
        safety++;
      }
    }

    // Colchón de gasto variable: gasto mensual reciente por encima de lo
    // recurrente. Nunca negativo.
    final variableMonthly =
        (avgTotalMonthlyExpenseUsd - recurringMonthlyExpense)
            .clamp(0.0, double.infinity)
            .toDouble();

    final points = <ProjectionPoint>[];
    var running = startingBalanceUsd;
    for (var i = 0; i < horizonMonths; i++) {
      final inc = incomeByMonth[i];
      final exp = expenseByMonth[i] + variableMonthly;
      running += inc - exp;
      points.add(
        ProjectionPoint(
          month: DateTime(firstMonth.year, firstMonth.month + i, 1),
          incomeUsd: inc,
          expenseUsd: exp,
          balanceUsd: running,
        ),
      );
    }

    return ProjectionResult(
      startingBalanceUsd: startingBalanceUsd,
      variableMonthlyExpenseUsd: variableMonthly,
      recurringMonthlyIncomeUsd: recurringMonthlyIncome,
      recurringMonthlyExpenseUsd: recurringMonthlyExpense,
      points: points,
      hasMissingRate: hasMissingRate,
    );
  }
}
