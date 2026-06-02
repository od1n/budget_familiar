import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/ai_proxy_service.dart';

void main() {
  // ── AiOcrResult ─────────────────────────────────────────────────────────────

  group('AiOcrResult.isSuccess', () {
    test('sin error → true', () {
      const result = AiOcrResult(amount: '25.50', description: 'Supermercado');
      expect(result.isSuccess, true);
    });

    test('con error → false', () {
      const result = AiOcrResult(error: 'pro_required');
      expect(result.isSuccess, false);
    });

    test('todos los campos null excepto error → false', () {
      const result = AiOcrResult(error: 'Error de conexión');
      expect(result.isSuccess, false);
    });

    test('resultado vacío sin error → true', () {
      const result = AiOcrResult();
      expect(result.isSuccess, true);
    });
  });

  // ── AiRecommendation.fromJson ───────────────────────────────────────────────

  group('AiRecommendation.fromJson', () {
    test('JSON completo → todos los campos mapeados', () {
      final json = {
        'title': 'Reducir gastos de servicios',
        'description': 'Optimiza el consumo eléctrico.',
        'priority': 'high',
        'category': 'gasto',
      };
      final rec = AiRecommendation.fromJson(json);
      expect(rec.title, 'Reducir gastos de servicios');
      expect(rec.description, 'Optimiza el consumo eléctrico.');
      expect(rec.priority, 'high');
      expect(rec.category, 'gasto');
    });

    test('JSON vacío → defaults aplicados', () {
      final rec = AiRecommendation.fromJson({});
      expect(rec.title, '');
      expect(rec.description, '');
      expect(rec.priority, 'medium');
      expect(rec.category, 'ahorro');
    });

    test('priority faltante → default medium', () {
      final rec = AiRecommendation.fromJson({
        'title': 'Test',
        'description': 'Desc',
        'category': 'divisa',
      });
      expect(rec.priority, 'medium');
    });

    test('category faltante → default ahorro', () {
      final rec = AiRecommendation.fromJson({
        'title': 'Test',
        'description': 'Desc',
        'priority': 'low',
      });
      expect(rec.category, 'ahorro');
    });

    test('valores null en JSON → defaults aplicados', () {
      final rec = AiRecommendation.fromJson({
        'title': null,
        'description': null,
        'priority': null,
        'category': null,
      });
      expect(rec.title, '');
      expect(rec.priority, 'medium');
      expect(rec.category, 'ahorro');
    });

    test('todas las prioridades válidas se preservan', () {
      for (final priority in ['high', 'medium', 'low']) {
        final rec = AiRecommendation.fromJson({'priority': priority});
        expect(rec.priority, priority);
      }
    });

    test('todas las categorías válidas se preservan', () {
      for (final cat in ['ahorro', 'gasto', 'inversión', 'deuda', 'divisa']) {
        final rec = AiRecommendation.fromJson({'category': cat});
        expect(rec.category, cat);
      }
    });
  });

  // ── InvestmentContext.toJson ────────────────────────────────────────────────

  group('InvestmentContext.toJson', () {
    test('campos escalares correctos', () {
      final ctx = InvestmentContext(
        income: 1500.0,
        expense: 800.0,
        balance: 700.0,
        month: 'Mayo 2026',
        currency: 'USD',
        topCategories: [],
        savingsGoals: [],
      );
      final json = ctx.toJson();
      expect(json['income'], 1500.0);
      expect(json['expense'], 800.0);
      expect(json['balance'], 700.0);
      expect(json['month'], 'Mayo 2026');
      expect(json['currency'], 'USD');
    });

    test('topCategories serializa correctamente', () {
      final ctx = InvestmentContext(
        income: 0,
        expense: 0,
        balance: 0,
        month: 'Enero 2026',
        currency: 'USD',
        topCategories: [
          (name: 'Alimentación', amount: 250.0),
          (name: 'Transporte', amount: 80.0),
        ],
        savingsGoals: [],
      );
      final json = ctx.toJson();
      final cats = json['top_categories'] as List;
      expect(cats.length, 2);
      expect(cats[0]['name'], 'Alimentación');
      expect(cats[0]['amount'], 250.0);
      expect(cats[1]['name'], 'Transporte');
    });

    test('savingsGoals serializa correctamente', () {
      final ctx = InvestmentContext(
        income: 0,
        expense: 0,
        balance: 0,
        month: 'Enero 2026',
        currency: 'USD',
        topCategories: [],
        savingsGoals: [
          (name: 'Fondo emergencia', current: 500.0, target: 2000.0),
        ],
      );
      final json = ctx.toJson();
      final goals = json['savings_goals'] as List;
      expect(goals.length, 1);
      expect(goals[0]['name'], 'Fondo emergencia');
      expect(goals[0]['current'], 500.0);
      expect(goals[0]['target'], 2000.0);
    });

    test('listas vacías → arrays vacíos en JSON', () {
      final ctx = InvestmentContext(
        income: 0,
        expense: 0,
        balance: 0,
        month: '',
        currency: 'USD',
        topCategories: [],
        savingsGoals: [],
      );
      final json = ctx.toJson();
      expect(json['top_categories'], isEmpty);
      expect(json['savings_goals'], isEmpty);
    });
  });
}
