import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_familiar/core/services/subscription_service.dart';

void main() {
  // ── SubscriptionState — lógica pura ────────────────────────────────────────

  group('SubscriptionState.isActive', () {
    test('free → false', () {
      expect(SubscriptionState.free.isActive, false);
    });

    test('beta sin expiresAt (sin vencimiento) → true', () {
      const state = SubscriptionState(planName: 'beta');
      expect(state.isActive, true);
    });

    test('family con expiresAt futuro → true', () {
      final state = SubscriptionState(
        planName: 'family',
        billingCycle: 'monthly',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(state.isActive, true);
    });

    test('premium con expiresAt pasado → false', () {
      final state = SubscriptionState(
        planName: 'premium',
        billingCycle: 'monthly',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(state.isActive, false);
    });

    test('free con expiresAt futuro → false', () {
      final state = SubscriptionState(
        planName: 'free',
        expiresAt: DateTime.now().add(const Duration(days: 10)),
      );
      expect(state.isActive, false);
    });
  });

  group('SubscriptionState.isPremium alias', () {
    test('isPremium == isActive', () {
      const active = SubscriptionState(planName: 'family');
      expect(active.isPremium, active.isActive);

      expect(SubscriptionState.free.isPremium, SubscriptionState.free.isActive);
    });
  });

  group('SubscriptionState.tier', () {
    test('free → PlanTier.free', () {
      expect(SubscriptionState.free.tier, PlanTier.free);
    });

    test('family → PlanTier.family', () {
      const s = SubscriptionState(planName: 'family');
      expect(s.tier, PlanTier.family);
    });

    test('premium → PlanTier.premium', () {
      const s = SubscriptionState(planName: 'premium');
      expect(s.tier, PlanTier.premium);
    });

    test('beta → PlanTier.beta', () {
      const s = SubscriptionState(planName: 'beta');
      expect(s.tier, PlanTier.beta);
    });

    test('desconocido → PlanTier.free', () {
      const s = SubscriptionState(planName: 'unknown_plan');
      expect(s.tier, PlanTier.free);
    });
  });

  group('SubscriptionState.planLabel', () {
    test('family monthly', () {
      const s = SubscriptionState(planName: 'family', billingCycle: 'monthly');
      expect(s.planLabel, 'Familiar');
    });

    test('family annual', () {
      const s = SubscriptionState(planName: 'family', billingCycle: 'annual');
      expect(s.planLabel, 'Familiar Anual');
    });

    test('premium monthly', () {
      const s = SubscriptionState(planName: 'premium', billingCycle: 'monthly');
      expect(s.planLabel, 'Premium');
    });

    test('premium annual', () {
      const s = SubscriptionState(planName: 'premium', billingCycle: 'annual');
      expect(s.planLabel, 'Premium Anual');
    });

    test('beta', () {
      const s = SubscriptionState(planName: 'beta');
      expect(s.planLabel, 'Beta Tester');
    });

    test('free → Gratuito', () {
      expect(SubscriptionState.free.planLabel, 'Gratuito');
    });

    test('plan desconocido → Gratuito', () {
      const s = SubscriptionState(planName: 'unknown_plan');
      expect(s.planLabel, 'Gratuito');
    });
  });

  group('SubscriptionState.capabilities', () {
    test('free tiene límites mínimos', () {
      const s = SubscriptionState.free;
      expect(s.canExportPdf, false);
      expect(s.canUseAi, false);
      expect(s.canUseDesktop, false);
      expect(s.hasGroupAccess, false);
      expect(s.maxMembers, 2);
      expect(s.maxCustomCategories, 10);
    });

    test('family tiene acceso familiar', () {
      const s = SubscriptionState(planName: 'family');
      expect(s.canExportPdf, true);
      expect(s.canUseAi, false);
      expect(s.canUseDesktop, true);
      expect(s.hasGroupAccess, true);
      expect(s.maxMembers, 5);
      expect(s.maxCustomCategories, 30);
    });

    test('premium tiene acceso completo', () {
      const s = SubscriptionState(planName: 'premium');
      expect(s.canExportPdf, true);
      expect(s.canUseAi, true);
      expect(s.canUseDesktop, true);
      expect(s.hasGroupAccess, true);
      expect(s.maxMembers, 10);
      expect(s.maxCustomCategories, 50);
    });

    test('beta tiene acceso completo', () {
      const s = SubscriptionState(planName: 'beta');
      expect(s.canExportPdf, true);
      expect(s.canUseAi, true);
      expect(s.canUseDesktop, true);
      expect(s.hasGroupAccess, true);
      expect(s.maxMembers, 10);
      expect(s.maxCustomCategories, 50);
    });
  });

  group('SubscriptionState.copyWith', () {
    test('copia cambiando planName', () {
      final original = SubscriptionState.free;
      final updated = original.copyWith(planName: 'family', billingCycle: 'monthly');
      expect(updated.planName, 'family');
      expect(updated.billingCycle, 'monthly');
    });

    test('sin argumentos devuelve copia igual', () {
      const original = SubscriptionState(planName: 'premium', billingCycle: 'annual');
      final copy = original.copyWith();
      expect(copy.planName, 'premium');
      expect(copy.billingCycle, 'annual');
    });
  });

  group('PlanTier.includes', () {
    test('premium includes family', () {
      expect(PlanTier.premium.includes(PlanTier.family), true);
    });

    test('family does not include premium', () {
      expect(PlanTier.family.includes(PlanTier.premium), false);
    });

    test('beta includes everything', () {
      expect(PlanTier.beta.includes(PlanTier.free), true);
      expect(PlanTier.beta.includes(PlanTier.family), true);
      expect(PlanTier.beta.includes(PlanTier.premium), true);
    });

    test('free only includes free', () {
      expect(PlanTier.free.includes(PlanTier.free), true);
      expect(PlanTier.free.includes(PlanTier.family), false);
    });
  });

  // ── SubscriptionService.loadFromCache ──────────────────────────────────────

  group('SubscriptionService.loadFromCache', () {
    setUp(() {
      SubscriptionService.instance.clearCache();
    });

    test('caché vacío → estado free', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await SubscriptionService.instance.loadFromCache();
      expect(state.isActive, false);
      expect(state.planName, 'free');
      expect(state.expiresAt, null);
    });

    test('caché con family mensual', () async {
      final expires = DateTime(2025, 6, 1).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'sub_plan_name': 'family',
        'sub_billing_cycle': 'monthly',
        'sub_expires_at': expires,
      });

      final state = await SubscriptionService.instance.loadFromCache();
      expect(state.planName, 'family');
      expect(state.billingCycle, 'monthly');
      expect(state.expiresAt, DateTime(2025, 6, 1));
    });

    test('caché con premium anual sin fecha expiración', () async {
      SharedPreferences.setMockInitialValues({
        'sub_plan_name': 'premium',
        'sub_billing_cycle': 'annual',
      });

      final state = await SubscriptionService.instance.loadFromCache();
      expect(state.planName, 'premium');
      expect(state.billingCycle, 'annual');
      expect(state.expiresAt, null);
    });

    test('migración desde caché antigua (is_premium bool)', () async {
      SharedPreferences.setMockInitialValues({
        'sub_is_premium': true,
        'sub_plan': 'monthly',
      });

      final state = await SubscriptionService.instance.loadFromCache();
      expect(state.planName, 'premium');
      expect(state.billingCycle, 'monthly');
    });

    test('clearCache resetea a estado free', () async {
      SharedPreferences.setMockInitialValues({
        'sub_plan_name': 'family',
        'sub_billing_cycle': 'monthly',
      });

      await SubscriptionService.instance.loadFromCache();
      expect(SubscriptionService.instance.state.isActive, true);

      await SubscriptionService.instance.clearCache();
      expect(SubscriptionService.instance.state.isActive, false);
      expect(SubscriptionService.instance.state.planName, 'free');
    });

    test('expiresAt con formato inválido → null (no crash)', () async {
      SharedPreferences.setMockInitialValues({
        'sub_plan_name': 'family',
        'sub_billing_cycle': 'monthly',
        'sub_expires_at': 'fecha-invalida',
      });

      final state = await SubscriptionService.instance.loadFromCache();
      expect(state.planName, 'family');
      expect(state.expiresAt, null);
    });
  });
}
