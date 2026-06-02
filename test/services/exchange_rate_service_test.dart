import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_familiar/core/services/exchange_rate_service.dart';

void main() {
  // ── VesRates — modelo puro ──────────────────────────────────────────────────

  group('VesRates.isStale', () {
    test('fresca (< 4 horas) → false', () {
      final rates = VesRates(
        bcv: 36,
        parallel: 37,
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(rates.isStale, false);
    });

    test('exactamente 4 horas → true', () {
      final rates = VesRates(
        bcv: 36,
        parallel: 37,
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      );
      expect(rates.isStale, true);
    });

    test('más de 4 horas → true', () {
      final rates = VesRates(
        bcv: 36,
        parallel: 37,
        updatedAt: DateTime.now().subtract(const Duration(hours: 10)),
      );
      expect(rates.isStale, true);
    });

    test('recién creada → false', () {
      final rates = VesRates(
        bcv: 36,
        parallel: 37,
        updatedAt: DateTime.now(),
      );
      expect(rates.isStale, false);
    });
  });

  group('VesRates.empty', () {
    test('bcv y parallel son 0', () {
      expect(VesRates.empty.bcv, 0);
      expect(VesRates.empty.parallel, 0);
    });

    test('isStale es true (fecha año 2000)', () {
      expect(VesRates.empty.isStale, true);
    });
  });

  // ── ExchangeRateService.loadCached ─────────────────────────────────────────

  group('ExchangeRateService.loadCached', () {
    late ExchangeRateService service;

    setUp(() {
      service = ExchangeRateService();
    });

    test('sin caché → null', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await service.loadCached();
      expect(result, isNull);
    });

    test('caché completo → VesRates con valores correctos', () async {
      final now = DateTime(2024, 6, 15, 10, 0, 0);
      SharedPreferences.setMockInitialValues({
        'er_bcv': 36.50,
        'er_parallel': 37.80,
        'er_updated_at': now.toIso8601String(),
      });

      final result = await service.loadCached();
      expect(result, isNotNull);
      expect(result!.bcv, 36.50);
      expect(result.parallel, 37.80);
      expect(result.updatedAt, now);
    });

    test('caché con campo faltante → null', () async {
      SharedPreferences.setMockInitialValues({
        'er_bcv': 36.50,
        // falta er_parallel y er_updated_at
      });

      final result = await service.loadCached();
      expect(result, isNull);
    });

    test('caché guardado hace 5 horas → isStale = true', () async {
      final old = DateTime.now().subtract(const Duration(hours: 5));
      SharedPreferences.setMockInitialValues({
        'er_bcv': 36.50,
        'er_parallel': 37.80,
        'er_updated_at': old.toIso8601String(),
      });

      final result = await service.loadCached();
      expect(result, isNotNull);
      expect(result!.isStale, true);
    });

    test('caché guardado hace 1 hora → isStale = false', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'er_bcv': 36.50,
        'er_parallel': 37.80,
        'er_updated_at': recent.toIso8601String(),
      });

      final result = await service.loadCached();
      expect(result!.isStale, false);
    });
  });

  // ── ExchangeRateService.getRates — lógica de caché ─────────────────────────

  group('ExchangeRateService.getRates — caché fresca', () {
    test('retorna caché sin llamar al servidor si está fresca', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'er_bcv': 40.0,
        'er_parallel': 41.0,
        'er_updated_at': recent.toIso8601String(),
      });

      final service = ExchangeRateService();
      // No mockeamos fetchRemote — si lo llama, fallaría en tests (sin red).
      // getRates debe devolver la caché directamente.
      final result = await service.getRates();
      expect(result, isNotNull);
      expect(result!.bcv, 40.0);
      expect(result.parallel, 41.0);
    });
  });
}
