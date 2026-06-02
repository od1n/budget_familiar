import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';

import 'supabase_service.dart';

final _log = Logger();

// ── Product IDs (deben coincidir con los creados en Play Console) ────────────

const kFamilyMonthlyId = 'family_monthly';
const kFamilyAnnualId = 'family_annual';
// const kPremiumMonthlyId = 'premium_monthly'; // futuro

const _kProductIds = {kFamilyMonthlyId, kFamilyAnnualId};

// ── Servicio ────────────────────────────────────────────────────────────────

/// Gestiona compras in-app via Google Play Billing.
/// Solo activo en Android/iOS — en desktop es no-op.
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _available = false;
  bool get isAvailable => _available;

  /// Solo funciona en móvil.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Se invoca cuando una compra se completa exitosamente.
  void Function(PurchaseDetails purchase)? onPurchaseSuccess;

  /// Se invoca cuando una compra falla o es cancelada.
  void Function(String error)? onPurchaseError;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (!isSupported) return;

    _available = await _iap.isAvailable();
    if (!_available) {
      _log.w('IapService: tienda no disponible');
      return;
    }

    // Escuchar stream de compras (renovaciones, pendientes, etc.)
    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => _log.e('IapService: stream error', error: e),
    );

    // Cargar productos disponibles
    final response = await _iap.queryProductDetails(_kProductIds);
    if (response.error != null) {
      _log.w('IapService: error cargando productos: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      _log.w('IapService: productos no encontrados: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    _log.i('IapService: ${_products.length} productos cargados');
  }

  // ── Comprar ───────────────────────────────────────────────────────────────

  /// Inicia el flujo de compra de Google Play.
  Future<bool> buy(ProductDetails product) async {
    if (!_available) return false;

    final param = PurchaseParam(productDetails: product);
    // Suscripciones usan buyNonConsumable (auto-renovable).
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restaura compras previas (útil si el usuario cambió de dispositivo).
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  // ── Manejo de eventos ─────────────────────────────────────────────────────

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          _log.w('IapService: compra falló: ${purchase.error?.message}');
          onPurchaseError?.call(
            purchase.error?.message ?? 'Error desconocido',
          );
          break;
        case PurchaseStatus.canceled:
          _log.i('IapService: compra cancelada');
          onPurchaseError?.call('Compra cancelada');
          break;
        case PurchaseStatus.pending:
          _log.i('IapService: compra pendiente');
          break;
      }

      // Siempre completar la transacción para evitar que quede pendiente.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Verifica el recibo con Supabase y activa el plan.
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _log.w('IapService: no hay usuario autenticado');
        return;
      }

      // Determinar plan y ciclo desde el productID.
      final (planName, billing) = _planFromProductId(purchase.productID);

      // Verificar y registrar en Supabase via Edge Function.
      // La Edge Function valida el token de compra con Google Play
      // Developer API y actualiza profiles.plan_name.
      await supabase.functions.invoke(
        'verify-purchase',
        body: {
          'user_id': userId,
          'product_id': purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
          'plan_name': planName,
          'billing_cycle': billing,
          'source': 'google_play',
        },
      );

      _log.i('IapService: compra verificada → $planName ($billing)');
      onPurchaseSuccess?.call(purchase);
    } catch (e) {
      _log.e('IapService: error verificando compra', error: e);
      // Aún así notificar éxito parcial — el usuario pagó,
      // el refresh desde Supabase lo corregirá.
      onPurchaseSuccess?.call(purchase);
    }
  }

  (String, String) _planFromProductId(String productId) => switch (productId) {
        kFamilyMonthlyId => ('family', 'monthly'),
        kFamilyAnnualId => ('family', 'annual'),
        _ => ('family', 'monthly'),
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Busca un producto por ID.
  ProductDetails? findProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
