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
    this.bcvEur = 0,
    this.parallelEur = 0,
    this.eurUsd = 0,
    this.usdMxn = 0,
    this.usdArsOficial = 0,
    this.usdArsBlue = 0,
  });

  /// Bs. por 1 USD — tasa BCV oficial.
  final double bcv;

  /// Bs. por 1 USD — tasa paralela / monitor.
  final double parallel;

  /// Bs. por 1 EUR — tasa BCV oficial (euro).
  final double bcvEur;

  /// Bs. por 1 EUR — tasa paralela (euro).
  final double parallelEur;

  /// USD por 1 EUR — tasa forex real de mercado (ECB / frankfurter).
  /// Es la tasa correcta para convertir EUR↔USD globalmente (usuarios europeos).
  final double eurUsd;

  /// MXN por 1 USD — peso mexicano (una sola tasa de mercado).
  final double usdMxn;

  /// ARS por 1 USD — peso argentino, tasa oficial.
  final double usdArsOficial;

  /// ARS por 1 USD — peso argentino, tasa "blue" (paralela).
  final double usdArsBlue;

  final DateTime updatedAt;

  bool get isStale => DateTime.now().difference(updatedAt).inHours >= 4;

  /// USD por 1 EUR (forex real). 0 si no hay tasa disponible.
  double get usdPerEur => eurUsd;

  static final empty = VesRates(bcv: 0, parallel: 0, updatedAt: DateTime(2000));
}

// ── Claves SharedPreferences ──────────────────────────────────────────────────

// v2: se cambian las claves para invalidar la caché con el BCV incorrecto
// (bug de mapeo previo que guardaba el paralelo como BCV).
const _kBcv = 'er_bcv_v3';
const _kParallel = 'er_parallel_v3';
const _kBcvEur = 'er_bcv_eur_v3';
const _kParallelEur = 'er_parallel_eur_v3';
const _kEurUsd = 'er_eur_usd_v3';
const _kUpdatedAt = 'er_updated_at_v3';
// Nuevas monedas (v1).
const _kUsdMxn = 'er_usd_mxn_v1';
const _kUsdArsOf = 'er_usd_ars_of_v1';
const _kUsdArsBlue = 'er_usd_ars_blue_v1';

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
      bcvEur: prefs.getDouble(_kBcvEur) ?? 0,
      parallelEur: prefs.getDouble(_kParallelEur) ?? 0,
      eurUsd: prefs.getDouble(_kEurUsd) ?? 0,
      usdMxn: prefs.getDouble(_kUsdMxn) ?? 0,
      usdArsOficial: prefs.getDouble(_kUsdArsOf) ?? 0,
      usdArsBlue: prefs.getDouble(_kUsdArsBlue) ?? 0,
      updatedAt: DateTime.parse(ts),
    );
  }

  Future<void> _cache(VesRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBcv, rates.bcv);
    await prefs.setDouble(_kParallel, rates.parallel);
    await prefs.setDouble(_kBcvEur, rates.bcvEur);
    await prefs.setDouble(_kParallelEur, rates.parallelEur);
    await prefs.setDouble(_kEurUsd, rates.eurUsd);
    await prefs.setDouble(_kUsdMxn, rates.usdMxn);
    await prefs.setDouble(_kUsdArsOf, rates.usdArsOficial);
    await prefs.setDouble(_kUsdArsBlue, rates.usdArsBlue);
    await prefs.setString(_kUpdatedAt, rates.updatedAt.toIso8601String());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Promedio de compra/venta de un objeto de dolarApi ({compra, venta}).
  /// Si solo hay uno de los dos, usa ese. 0 si no hay nada válido.
  double _avgCompraVenta(dynamic obj) {
    if (obj is! Map) return 0;
    final c = (obj['compra'] as num?)?.toDouble() ?? 0;
    final v = (obj['venta'] as num?)?.toDouble() ?? 0;
    if (c > 0 && v > 0) return (c + v) / 2;
    if (v > 0) return v;
    if (c > 0) return c;
    return 0;
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

        // El discriminador confiable es `fuente` ('oficial' | 'paralelo').
        // OJO: el objeto oficial trae nombre "Dólar" (NO "Oficial"), por eso
        // buscar 'oficial' dentro de `nombre` fallaba y bcv quedaba null.
        if (fuente == 'oficial' || fuente == 'bcv' || nombre.contains('oficial')) {
          bcv = promedio;
        } else if (fuente == 'paralelo' ||
            nombre.contains('paralel') ||
            nombre.contains('monitor')) {
          parallel = promedio;
        }
      }

      if (bcv == null && parallel == null) return null;

      // Sin fallback cruzado: si falta una tasa se guarda 0 (= "no disponible"),
      // que la UI ya maneja con sus guardas `> 0`. NUNCA mostrar el paralelo
      // como si fuera el BCV (ni al revés).
      if (bcv == null || parallel == null) {
        _log.w('ExchangeRates: falta ${bcv == null ? "BCV" : "paralela"} '
            'en la respuesta de ve.dolarapi.com');
      }

      // ── Euro (ve.dolarapi.com/v1/euros) — no fatal si falla ──────────────
      double bcvEur = 0, parallelEur = 0;
      try {
        final eurResp =
            await _dio.get<List>('https://ve.dolarapi.com/v1/euros');
        final eurList = eurResp.data;
        if (eurList != null) {
          for (final item in eurList) {
            final fuente = (item['fuente'] as String? ?? '').toLowerCase();
            final promedio = (item['promedio'] as num?)?.toDouble() ?? 0;
            if (promedio <= 0) continue;
            if (fuente == 'oficial' || fuente == 'bcv') {
              bcvEur = promedio;
            } else if (fuente == 'paralelo') {
              parallelEur = promedio;
            }
          }
        }
      } catch (e) {
        _log.w('ExchangeRates euro (Bs) fetch/parse: $e');
      }

      // ── Forex real EUR/USD (ECB vía frankfurter; respaldo open.er-api) ────
      double eurUsd = 0;
      try {
        final fx = await _dio.get<Map>(
          'https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD',
        );
        final usd = ((fx.data?['rates'] as Map?)?['USD'] as num?)?.toDouble();
        if (usd != null && usd > 0) eurUsd = usd;
      } catch (e) {
        _log.w('ExchangeRates forex frankfurter: $e');
      }
      if (eurUsd <= 0) {
        try {
          final fx2 = await _dio.get<Map>('https://open.er-api.com/v6/latest/EUR');
          final usd = ((fx2.data?['rates'] as Map?)?['USD'] as num?)?.toDouble();
          if (usd != null && usd > 0) eurUsd = usd;
        } catch (e) {
          _log.w('ExchangeRates forex fallback: $e');
        }
      }

      // ── Peso mexicano MXN (mx.dolarapi.com; respaldo frankfurter) ─────────
      double usdMxn = 0;
      try {
        final mx =
            await _dio.get<List>('https://mx.dolarapi.com/v1/cotizaciones');
        final mxList = mx.data;
        if (mxList != null) {
          for (final item in mxList) {
            final moneda = (item['moneda'] as String? ?? '').toUpperCase();
            if (moneda == 'USD') {
              final avg = _avgCompraVenta(item);
              if (avg > 0) usdMxn = avg;
              break;
            }
          }
        }
      } catch (e) {
        _log.w('ExchangeRates MXN dolarapi: $e');
      }
      if (usdMxn <= 0) {
        try {
          final fx = await _dio.get<Map>(
            'https://api.frankfurter.dev/v1/latest?base=USD&symbols=MXN',
          );
          final v = ((fx.data?['rates'] as Map?)?['MXN'] as num?)?.toDouble();
          if (v != null && v > 0) usdMxn = v;
        } catch (e) {
          _log.w('ExchangeRates MXN frankfurter: $e');
        }
      }

      // ── Peso argentino ARS: oficial + blue ────────────────────────────────
      // Primario: ar.dolarapi.com (objetos individuales por casa).
      // Respaldo: api.bluelytics.com.ar (oficial y blue en un solo objeto).
      double usdArsOficial = 0, usdArsBlue = 0;
      try {
        final of =
            await _dio.get<Map>('https://ar.dolarapi.com/v1/dolares/oficial');
        usdArsOficial = _avgCompraVenta(of.data);
      } catch (e) {
        _log.w('ExchangeRates ARS oficial dolarapi: $e');
      }
      try {
        final bl =
            await _dio.get<Map>('https://ar.dolarapi.com/v1/dolares/blue');
        usdArsBlue = _avgCompraVenta(bl.data);
      } catch (e) {
        _log.w('ExchangeRates ARS blue dolarapi: $e');
      }
      if (usdArsOficial <= 0 || usdArsBlue <= 0) {
        try {
          final bly =
              await _dio.get<Map>('https://api.bluelytics.com.ar/v2/latest');
          if (usdArsOficial <= 0) {
            final v = ((bly.data?['oficial'] as Map?)?['value_avg'] as num?)
                ?.toDouble();
            if (v != null && v > 0) usdArsOficial = v;
          }
          if (usdArsBlue <= 0) {
            final v =
                ((bly.data?['blue'] as Map?)?['value_avg'] as num?)?.toDouble();
            if (v != null && v > 0) usdArsBlue = v;
          }
        } catch (e) {
          _log.w('ExchangeRates ARS bluelytics: $e');
        }
      }

      final rates = VesRates(
        bcv: bcv ?? 0,
        parallel: parallel ?? 0,
        bcvEur: bcvEur,
        parallelEur: parallelEur,
        eurUsd: eurUsd,
        usdMxn: usdMxn,
        usdArsOficial: usdArsOficial,
        usdArsBlue: usdArsBlue,
        updatedAt: DateTime.now(),
      );
      await _cache(rates);
      _log.i('ExchangeRates: BCV=${rates.bcv} Paralela=${rates.parallel} '
          'BCV€=${rates.bcvEur} Paralela€=${rates.parallelEur} '
          'EUR/USD=${rates.eurUsd} MXN=${rates.usdMxn} '
          'ARS_of=${rates.usdArsOficial} ARS_blue=${rates.usdArsBlue}');
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
