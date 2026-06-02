import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

final _log = Logger();

// ── IDs de prueba de Google (reemplazar con IDs reales en producción) ────────
// Documentación: https://developers.google.com/admob/android/test-ads

const _kTestBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _kTestBannerIos = 'ca-app-pub-3940256099942544/2934735716';

// ── Para producción, configurar aquí los IDs reales: ────────────────────────
// const _kBannerAndroid = 'ca-app-pub-XXXX/YYYY';
// const _kBannerIos = 'ca-app-pub-XXXX/ZZZZ';

// ── Servicio ────────────────────────────────────────────────────────────────

class AdService {
  BannerAd? _bannerAd;
  bool _isInitialized = false;

  /// Solo disponible en Android/iOS.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Inicializa el SDK de Mobile Ads. Llamar una vez al inicio.
  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _log.i('AdService: inicializado correctamente');
    } catch (e) {
      _log.w('AdService: error al inicializar: $e');
    }
  }

  /// Carga un banner ad. Retorna el BannerAd para mostrarlo en un widget.
  BannerAd? loadBanner({
    AdSize size = AdSize.banner,
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    if (!isSupported || !_isInitialized) return null;

    final adUnitId = Platform.isAndroid ? _kTestBannerAndroid : _kTestBannerIos;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _log.i('AdService: banner cargado');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          _log.w('AdService: banner falló: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          onFailed?.call();
        },
      ),
    )..load();

    return _bannerAd;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final adServiceProvider = Provider<AdService>((_) => AdService());

// ── Widget de banner ────────────────────────────────────────────────────────

/// Widget que muestra un banner de AdMob.
/// Solo se renderiza si el plan es Free y la plataforma es móvil.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    final svc = ref.read(adServiceProvider);
    if (!svc.isSupported) return;

    _ad = svc.loadBanner(
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
