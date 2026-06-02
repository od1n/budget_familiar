import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/notification_service.dart';

void main() {
  // ── NotificationService.isoWeekKey ─────────────────────────────────────────
  // Verifica el cálculo de semana ISO 8601.
  // Regla: la semana 1 es la que contiene el primer jueves de enero.

  group('NotificationService.isoWeekKey', () {
    test('primera semana de 2024', () {
      // 1 enero 2024 es lunes → semana 1
      expect(NotificationService.isoWeekKey(DateTime(2024, 1, 1)), '2024-W01');
    });

    test('última semana de 2023', () {
      // 31 diciembre 2023 es domingo → semana 52 de 2023
      expect(NotificationService.isoWeekKey(DateTime(2023, 12, 31)), '2023-W52');
    });

    test('semana 22 de 2026', () {
      // 31 mayo 2026 es domingo → semana 22
      expect(NotificationService.isoWeekKey(DateTime(2026, 5, 31)), '2026-W22');
    });

    test('mismo día produce la misma clave', () {
      final d = DateTime(2024, 6, 15);
      expect(
        NotificationService.isoWeekKey(d),
        NotificationService.isoWeekKey(d),
      );
    });

    test('días distintos de la misma semana producen la misma clave', () {
      // Semana del 10 al 16 de junio 2024 (lunes a domingo)
      final lunes = DateTime(2024, 6, 10);
      final viernes = DateTime(2024, 6, 14);
      final domingo = DateTime(2024, 6, 16);
      expect(
        NotificationService.isoWeekKey(lunes),
        NotificationService.isoWeekKey(viernes),
      );
      expect(
        NotificationService.isoWeekKey(lunes),
        NotificationService.isoWeekKey(domingo),
      );
    });

    test('lunes y domingo de semanas distintas dan claves distintas', () {
      final domingo = DateTime(2024, 6, 9);  // fin de semana 23
      final lunes = DateTime(2024, 6, 10);   // inicio de semana 24
      expect(
        NotificationService.isoWeekKey(domingo),
        isNot(NotificationService.isoWeekKey(lunes)),
      );
    });

    test('formato siempre tiene dos dígitos en semana', () {
      // Semana 1 → W01, no W1
      final result = NotificationService.isoWeekKey(DateTime(2024, 1, 1));
      expect(result, matches(RegExp(r'^\d{4}-W\d{2}$')));
    });

    test('año de la clave puede diferir del año del día (semana 53)', () {
      // 1 enero 2016 es viernes → pertenece a semana 53 de 2015
      final result = NotificationService.isoWeekKey(DateTime(2016, 1, 1));
      expect(result, '2015-W53');
    });
  });
}
