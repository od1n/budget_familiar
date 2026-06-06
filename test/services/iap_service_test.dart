import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/iap_service.dart';

void main() {
  group('IapService constants', () {
    test('product IDs están definidos correctamente', () {
      expect(kFamilyMonthlyId, 'family_monthly');
      expect(kFamilyAnnualId, 'family_annual');
    });
  });

  // IapService.instance accede a InAppPurchase.instance que requiere
  // el plugin de plataforma. En tests unitarios no está disponible.
  // Estos tests se ejecutan en integration_test.
}
