import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger();

// ── Modelo ────────────────────────────────────────────────────────────────────

class VesRates {
  const VesRates({
    required this.bcv,
    required this.parallel,
    required this.updatedAt,
  });

  /// Bs. por 1 USD — tasa BCV oficial.
  final double bcv;

  /// Bs. por 1 USD — tasa paralela / monitor.
  final double parallel;

  final DateTime updatedAt;

  bool get isStale => DateTime.now().difference(updatedAt).inHours >= 4;

  static final empty = VesRates(bcv: 0, parallel: 0, updatedAt: DateTime(2000));
}

// ── Claves SharedPreferences ──────────────────────────────────────────────────

const _kBcv = 'er_bcv';
const _kParallel = 'er_parallel';
const _kUpdatedAt = 'er_updated_at';

// ── Servicio ──────────────────────────────────────────────────────────────────

class ExchangeRateService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // ── Caché local ───────────────────────────────────────────────────────────

  Future<VesRates?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final bcv = prefs.getDouble(_kBcv);
    final parallel = prefs.getDouble(_kParallel);
    final ts = prefs.getString(_kUpdatedAt);
    if (bcv == null || parallel == null || ts == null) return null;
    return VesRates(
      bcv: bcv,
      parallel: parallel,
      updatedAt: DateTime.parse(ts),
    );
  }

  Future<void> _cache(VesRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBcv, rates.bcv);
    await prefs.setDouble(_kParallel, rates.parallel);
    await prefs.setString(_kUpdatedAt, rates.updatedAt.toIso8601String());
  }

  // ── Fetch remoto ──────────────────────────────────────────────────────────
  // API: https://ve.dolarapi.com — sin clave, pública.
  // Responde un array con objetos {fuente, promedio, ...}.

  Future<VesRates?> fetchRemote() async {
    try {
      final resp = await _dio.get<List>('https://ve.dolarapi.com/v1/dolares');
      final list = resp.data;
      if (list == null || list.isEmpty) return null;

      double? bcv, parallel;
      for (final item in list) {
        final fuente = (item['fuente'] as String? ?? '').toLowerCase();
        final nombre = (item['nombre'] as String? ?? '').toLowerCase();
        final promedio = (item['promedio'] as num?)?.toDouble() ?? 0;
        if (promedio <= 0) continue;

        if (fuente == 'bcv' || nombre.contains('oficial')) {
          bcv = promedio;
        } else if (nombre.contains('paralel') || nombre.contains('monitor')) {
          parallel = promedio;
        }
      }

      if (bcv == null && parallel == null) return null;

      final rates = VesRates(
        bcv: bcv ?? parallel ?? 0,
        parallel: parallel ?? bcv ?? 0,
        updatedAt: DateTime.now(),
      );
      await _cache(rates);
      _log.i('ExchangeRates: BCV=${rates.bcv} Paralela=${rates.parallel}');
      return rates;
    } on DioException catch (e) {
      _log.w('ExchangeRates fetch failed: ${e.message}');
      return null;
    } catch (e) {
      _log.w('ExchangeRates parse error: $e');
      return null;
    }
  }

  /// Retorna caché si está fresca; si no, intenta fetch remoto y cae a caché.
  Future<VesRates?> getRates({bool forceRefresh = false}) async {
    final cached = await loadCached();
    if (cached != null && !cached.isStale && !forceRefresh) return cached;
    return await fetchRemote() ?? cached;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final exchangeRateServiceProvider = Provider<ExchangeRateService>(
  (_) => ExchangeRateService(),
);

final vesRatesProvider = FutureProvider.autoDispose<VesRates?>((ref) async {
  final svc = ref.read(exchangeRateServiceProvider);
  return svc.getRates();
});
