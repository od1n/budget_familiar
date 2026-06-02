import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../data/local/app_database.dart';
import '../../features/family/providers/family_provider.dart';
import 'ai_proxy_service.dart';

export 'ai_proxy_service.dart' show AiRecommendation, InvestmentContext;

final _log = Logger();

/// Genera recomendaciones financieras personalizadas usando el proxy de IA.
///
/// Recopila los datos del mes actual desde la base de datos local y los envía
/// al proxy. El proxy llama Gemini y retorna recomendaciones en JSON.
class InvestmentAdvisorService {
  InvestmentAdvisorService(this._db, this._groupId);

  final AppDatabase _db;
  final String _groupId;

  /// Genera recomendaciones para el mes y año indicados.
  /// [byokKey] es la Gemini API key propia del usuario (opcional).
  Future<({List<AiRecommendation> items, String? error})> getRecommendations({
    int? year,
    int? month,
    String? byokKey,
  }) async {
    if (_groupId.isEmpty) {
      return (items: <AiRecommendation>[], error: 'Sin grupo activo.');
    }

    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    try {
      // 1. Resumen mensual
      final summary = await _db.transactionsDao.getMonthlySummary(
        groupId: _groupId,
        year: y,
        month: m,
      );

      if (summary.count == 0) {
        return (
          items: <AiRecommendation>[],
          error: 'Sin transacciones en este mes para analizar.',
        );
      }

      // 2. Gastos por categoría
      final expByCategory = await _db.transactionsDao.getExpenseByCategory(
        groupId: _groupId,
        year: y,
        month: m,
      );

      // 3. Nombres de categorías
      final cats = await _db.categoriesDao.getCategoriesForGroup(_groupId);
      final catNames = {for (final c in cats) c.id: c.name};

      final topCategories = expByCategory.entries
          .map((e) => (
                name: catNames[e.key] ?? e.key,
                amount: e.value,
              ),)
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // 4. Metas de ahorro
      final goalsRaw = await (_db.select(_db.savingsGoalsTable)
            ..where((t) => t.groupId.equals(_groupId)))
          .get();

      final savingsGoals = goalsRaw
          .map((g) => (
                name: g.name,
                current: g.currentAmount,
                target: g.targetAmount,
              ),)
          .toList();

      // 5. Determinar moneda predominante
      final currency = summary.hasMixedCurrencies ? 'USD (aprox.)' : 'USD';

      final monthLabel = DateFormat('MMMM yyyy', 'es').format(DateTime(y, m));

      final context = InvestmentContext(
        income: summary.totalIncome,
        expense: summary.totalExpense,
        balance: summary.balance,
        month: monthLabel,
        currency: currency,
        topCategories: topCategories.take(5).toList(),
        savingsGoals: savingsGoals,
      );

      _log.i('InvestmentAdvisor: solicitando recomendaciones para $monthLabel');

      return AiProxyService.instance.getInvestmentRecommendations(
        context: context,
        byokKey: byokKey,
      );
    } catch (e) {
      _log.w('InvestmentAdvisorService error: $e');
      return (items: <AiRecommendation>[], error: 'Error al preparar datos: $e');
    }
  }
}

final investmentAdvisorProvider = Provider<InvestmentAdvisorService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final groupId = ref.watch(activeGroupIdProvider);
  return InvestmentAdvisorService(db, groupId);
});
