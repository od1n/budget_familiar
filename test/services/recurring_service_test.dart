import 'package:flutter_test/flutter_test.dart';
import 'package:budget_familiar/core/services/recurring_service.dart';

void main() {
  // advanceDate es un método estático público — testeable sin ningún mock.

  group('RecurringService.advanceDate', () {
    // ── daily ─────────────────────────────────────────────────────────────────

    group('daily', () {
      test('avanza exactamente un día', () {
        final date = DateTime(2024, 3, 15);
        final next = RecurringService.advanceDate(date, 'daily', null);
        expect(next, DateTime(2024, 3, 16));
      });

      test('cruza fin de mes', () {
        final date = DateTime(2024, 1, 31);
        final next = RecurringService.advanceDate(date, 'daily', null);
        expect(next, DateTime(2024, 2, 1));
      });
    });

    // ── weekly ────────────────────────────────────────────────────────────────

    group('weekly', () {
      test('avanza 7 días', () {
        final date = DateTime(2024, 3, 15);
        final next = RecurringService.advanceDate(date, 'weekly', null);
        expect(next, DateTime(2024, 3, 22));
      });

      test('cruza fin de mes', () {
        final date = DateTime(2024, 3, 28);
        final next = RecurringService.advanceDate(date, 'weekly', null);
        expect(next, DateTime(2024, 4, 4));
      });
    });

    // ── biweekly ──────────────────────────────────────────────────────────────

    group('biweekly', () {
      test('avanza 14 días', () {
        final date = DateTime(2024, 3, 1);
        final next = RecurringService.advanceDate(date, 'biweekly', null);
        expect(next, DateTime(2024, 3, 15));
      });
    });

    // ── monthly ───────────────────────────────────────────────────────────────

    group('monthly sin dayOfMonth', () {
      test('avanza un mes preservando el día', () {
        final date = DateTime(2024, 3, 15);
        final next = RecurringService.advanceDate(date, 'monthly', null);
        expect(next, DateTime(2024, 4, 15));
      });

      test('enero 31 → febrero 29 (año bisiesto 2024)', () {
        final date = DateTime(2024, 1, 31);
        final next = RecurringService.advanceDate(date, 'monthly', null);
        expect(next, DateTime(2024, 2, 29));
      });

      test('enero 31 → febrero 28 (año no bisiesto 2023)', () {
        final date = DateTime(2023, 1, 31);
        final next = RecurringService.advanceDate(date, 'monthly', null);
        expect(next, DateTime(2023, 2, 28));
      });

      test('diciembre → enero del año siguiente', () {
        final date = DateTime(2024, 12, 10);
        final next = RecurringService.advanceDate(date, 'monthly', null);
        expect(next, DateTime(2025, 1, 10));
      });
    });

    group('monthly con dayOfMonth', () {
      test('siempre usa el día fijo indicado', () {
        final date = DateTime(2024, 3, 15);
        final next = RecurringService.advanceDate(date, 'monthly', 1);
        expect(next, DateTime(2024, 4, 1));
      });

      test('día 31 en mes con 30 días → clamp a 30', () {
        // Marzo (31 días), dayOfMonth=31 → Abril tiene 30 días → 30
        final date = DateTime(2024, 3, 31);
        final next = RecurringService.advanceDate(date, 'monthly', 31);
        expect(next, DateTime(2024, 4, 30));
      });

      test('día 31 en febrero → clamp a 29 (año bisiesto)', () {
        final date = DateTime(2024, 1, 31);
        final next = RecurringService.advanceDate(date, 'monthly', 31);
        expect(next, DateTime(2024, 2, 29));
      });

      test('día 31 en febrero → clamp a 28 (año no bisiesto)', () {
        final date = DateTime(2023, 1, 31);
        final next = RecurringService.advanceDate(date, 'monthly', 31);
        expect(next, DateTime(2023, 2, 28));
      });

      test('día 15 en cualquier mes', () {
        final date = DateTime(2024, 6, 1);
        final next = RecurringService.advanceDate(date, 'monthly', 15);
        expect(next, DateTime(2024, 7, 15));
      });
    });

    // ── yearly ────────────────────────────────────────────────────────────────

    group('yearly', () {
      test('avanza exactamente un año', () {
        final date = DateTime(2024, 6, 15);
        final next = RecurringService.advanceDate(date, 'yearly', null);
        expect(next, DateTime(2025, 6, 15));
      });

      test('29 de febrero en año bisiesto → 28 de febrero en año no bisiesto', () {
        final date = DateTime(2024, 2, 29);
        final next = RecurringService.advanceDate(date, 'yearly', null);
        expect(next, DateTime(2025, 2, 28));
      });

      test('28 de febrero en año no bisiesto → 28 de febrero en siguiente año', () {
        final date = DateTime(2023, 2, 28);
        final next = RecurringService.advanceDate(date, 'yearly', null);
        expect(next, DateTime(2024, 2, 28));
      });

      test('31 de diciembre → 31 de diciembre del año siguiente', () {
        final date = DateTime(2024, 12, 31);
        final next = RecurringService.advanceDate(date, 'yearly', null);
        expect(next, DateTime(2025, 12, 31));
      });
    });

    // ── frecuencia desconocida ────────────────────────────────────────────────

    group('frecuencia desconocida', () {
      test('avanza 30 días como fallback', () {
        final date = DateTime(2024, 3, 1);
        final next = RecurringService.advanceDate(date, 'quincenal_raro', null);
        expect(next, DateTime(2024, 3, 31));
      });
    });
  });
}
