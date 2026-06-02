import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_familiar/core/services/biometric_service.dart';

void main() {
  group('BiometricService preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isEnabled retorna false por defecto', () async {
      final svc = BiometricService();
      expect(await svc.isEnabled, false);
    });

    test('setEnabled(true) persiste el valor', () async {
      final svc = BiometricService();
      await svc.setEnabled(true);
      expect(await svc.isEnabled, true);
    });

    test('setEnabled(false) desactiva', () async {
      final svc = BiometricService();
      await svc.setEnabled(true);
      await svc.setEnabled(false);
      expect(await svc.isEnabled, false);
    });

    test('valor persiste entre instancias', () async {
      final svc1 = BiometricService();
      await svc1.setEnabled(true);

      final svc2 = BiometricService();
      expect(await svc2.isEnabled, true);
    });
  });
}
