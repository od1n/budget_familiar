import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/deeplink_service.dart';

void main() {
  group('buildInviteLink', () {
    test('genera URI correcta', () {
      expect(
        buildInviteLink('AB3KP9MZ'),
        'budgetfamiliar://join/AB3KP9MZ',
      );
    });

    test('preserva mayúsculas/minúsculas', () {
      expect(
        buildInviteLink('xY7kM2pQ'),
        'budgetfamiliar://join/xY7kM2pQ',
      );
    });
  });

  group('DeeplinkService URI parsing', () {
    late DeeplinkService svc;

    setUp(() {
      svc = DeeplinkService();
    });

    tearDown(() {
      svc.dispose();
    });

    test('pendingInviteCode inicia null', () {
      expect(svc.pendingInviteCode.value, isNull);
    });

    test('consumePendingCode retorna null si no hay código', () {
      expect(svc.consumePendingCode(), isNull);
    });

    test('consumePendingCode retorna y limpia el código', () {
      // Simular que se recibió un código
      svc.pendingInviteCode.value = 'TEST1234';

      final code = svc.consumePendingCode();
      expect(code, 'TEST1234');
      expect(svc.pendingInviteCode.value, isNull);
    });

    test('consumePendingCode doble llamada retorna null la segunda vez', () {
      svc.pendingInviteCode.value = 'CODE0001';

      expect(svc.consumePendingCode(), 'CODE0001');
      expect(svc.consumePendingCode(), isNull);
    });
  });

  group('kAppScheme', () {
    test('es budgetfamiliar', () {
      expect(kAppScheme, 'budgetfamiliar');
    });
  });
}
