import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/iap_service.dart';

void main() {
  group('IapService constants', () {
    test('product IDs están definidos correctamente', () {
      expect(kFamilyMonthlyId, 'family_monthly');
      expect(kFamilyAnnualId, 'family_annual');
    });
  });

  group('IapService.instance', () {
    test('es singleton', () {
      final a = IapService.instance;
      final b = IapService.instance;
      expect(identical(a, b), true);
    });

    test('products inicia vacío', () {
      expect(IapService.instance.products, isEmpty);
    });

    test('isAvailable inicia false (no inicializado)', () {
      expect(IapService.instance.isAvailable, false);
    });
  });
}
