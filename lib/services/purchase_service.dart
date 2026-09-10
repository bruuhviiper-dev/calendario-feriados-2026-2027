import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'store_products.dart';

/// Compras REAIS via Google Play Billing (in_app_purchase). Concede o direito
/// (ex.: no_ads) somente quando o Google confirma a compra. Mantém a mesma API
/// pública usada pelo app (buy / priceOf / restore / onEntitlement).
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _details = {};
  final Map<String, Completer<PurchaseResult>> _pending = {};
  bool _available = false;

  void Function(String productId)? _onGrant;
  void Function(String productId)? _onSubGrant;
  void onEntitlement(void Function(String productId) cb) => _onGrant = cb;
  void onSubscriptionGranted(void Function(String productId) cb) =>
      _onSubGrant = cb;

  bool get isAvailable => _available;

  /// Preço real (vindo da loja) ou o fallback do catálogo.
  String priceOf(String productId) =>
      _details[productId]?.price ??
      StoreProducts.byId(productId)?.fallbackPrice ??
      '';

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );
    _available = await _iap.isAvailable();
    if (!_available) {
      notifyListeners();
      return;
    }
    final ids = StoreProducts.all.map((p) => p.id).toSet();
    try {
      final resp = await _iap.queryProductDetails(ids);
      for (final p in resp.productDetails) {
        _details[p.id] = p;
      }
    } catch (_) {}
    notifyListeners();
    // Restaura direitos já comprados (não-consumíveis) em segundo plano.
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<PurchaseResult> buy(String productId) async {
    if (!_available) return PurchaseResult.unavailable;
    final pd = _details[productId];
    if (pd == null) return PurchaseResult.unavailable;
    final completer = Completer<PurchaseResult>();
    _pending[productId] = completer;
    final param = PurchaseParam(productDetails: pd);
    try {
      if (StoreProducts.subscriptionIds.contains(productId)) {
        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        // no_ads é um direito permanente => não-consumível.
        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (_) {
      _pending.remove(productId);
      return PurchaseResult.error;
    }
    return completer.future;
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _grant(p.productID);
          _pending.remove(p.productID)?.complete(PurchaseResult.success);
          break;
        case PurchaseStatus.error:
          _pending.remove(p.productID)?.complete(PurchaseResult.error);
          break;
        case PurchaseStatus.canceled:
          _pending.remove(p.productID)?.complete(PurchaseResult.cancelled);
          break;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }
  }

  void _grant(String productId) {
    if (StoreProducts.subscriptionIds.contains(productId)) {
      _onSubGrant?.call(productId);
    } else {
      _onGrant?.call(productId);
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
