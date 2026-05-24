import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/shared/iap/iap_failure.dart';

/// Owns the [InAppPurchase] connection and translates store events into
/// updates on the "Remove Ads" entitlement stored in [IPreferencesRepository].
///
/// One product is exposed today — [removeAdsProductId]. The same id is used
/// on both App Store Connect and Google Play.
class IapService {
  IapService(this._preferences, this._analytics, {InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  /// The non-consumable "Remove Ads" product id. Must match the SKU configured
  /// in App Store Connect and Google Play Console.
  static const removeAdsProductId = 'flixsy_remove_ads';

  final IPreferencesRepository _preferences;
  final AnalyticsService _analytics;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  final StreamController<IapFailure> _failures =
      StreamController<IapFailure>.broadcast();

  /// User-visible failures (e.g. cancel, network) that the UI can surface
  /// via a snackbar.
  Stream<IapFailure> get failures => _failures.stream;

  /// The cached "Remove Ads" product details, or `null` until
  /// [queryProducts] has succeeded.
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  /// Begins listening for purchase updates. Must be called once at app start.
  Future<void> init() async {
    if (!await _iap.isAvailable()) return;
    _subscription = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        _failures.add(IapUnknownFailure(error.toString()));
      },
    );
  }

  /// Loads product metadata (localized price, title) for the IAPs we sell.
  Future<ProductDetails?> queryProducts() async {
    final response = await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isEmpty) {
      _failures.add(const IapProductNotFound());
      return null;
    }
    _removeAdsProduct = response.productDetails.firstWhere(
      (p) => p.id == removeAdsProductId,
    );
    return _removeAdsProduct;
  }

  /// Launches the platform purchase sheet for the "Remove Ads" product.
  Future<void> buyRemoveAds() async {
    final product = _removeAdsProduct ?? await queryProducts();
    if (product == null) return;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Asks the platform to replay any previously completed purchases — the
  /// stream handler will mark the entitlement true if a matching purchase
  /// is restored.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    var anyRestoredOrPurchased = false;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          _failures.add(const IapUserCancelled());
        case PurchaseStatus.error:
          _failures.add(
            IapUnknownFailure(purchase.error?.message ?? 'unknown'),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == removeAdsProductId) {
            await _preferences.setAdsRemoved(true);
            if (purchase.status == PurchaseStatus.restored) {
              await _analytics.logRestoreRemoveAds();
            } else {
              await _analytics.logPurchaseRemoveAds();
            }
            anyRestoredOrPurchased = true;
          }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    if (!anyRestoredOrPurchased &&
        purchases.isNotEmpty &&
        purchases.every((p) => p.status == PurchaseStatus.restored)) {
      _failures.add(const IapNothingToRestore());
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _failures.close();
  }
}
