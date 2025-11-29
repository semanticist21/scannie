import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Purchase result with error details
class PurchaseResult {
  final bool success;
  final PurchaseErrorType? errorType;
  final String? errorMessage;

  const PurchaseResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });

  factory PurchaseResult.success() => const PurchaseResult(success: true);

  factory PurchaseResult.error(PurchaseErrorType type, [String? message]) =>
      PurchaseResult(success: false, errorType: type, errorMessage: message);
}

/// Error types for user-friendly messages
enum PurchaseErrorType {
  storeNotAvailable,
  productNotFound,
  purchaseFailed,
  purchaseCancelled,
  networkError,
  unknown,
}

/// PurchaseService - Singleton service for managing in-app purchases
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// await PurchaseService.instance.initialize();
///
/// // Check premium status
/// final isPremium = await PurchaseService.instance.isPremium;
///
/// // Purchase premium
/// await PurchaseService.instance.purchasePremium();
///
/// // Restore purchases
/// await PurchaseService.instance.restorePurchases();
/// ```
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  static PurchaseService get instance => _instance;

  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isInitialized = false;
  ProductDetails? _premiumProduct;

  // Premium product ID (matches Play Console configuration)
  static const String premiumProductId = 'premium_remove_ads';

  // SharedPreferences key (same as AdService uses)
  static const String _premiumKey = 'isPremium';

  /// Check if store is available
  bool get isAvailable => _isAvailable;

  /// Get premium product details (for displaying price)
  ProductDetails? get premiumProduct => _premiumProduct;

  /// Get formatted price string
  String get priceString => _premiumProduct?.price ?? '\$2.00';

  /// Check if user has premium status
  Future<bool> get isPremium async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_premiumKey) ?? false;
    } catch (e) {
      debugPrint('💎 Failed to check premium status: $e');
      return false;
    }
  }

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        debugPrint('💎 In-app purchases not available');
        _isInitialized = true;
        return;
      }

      debugPrint('💎 In-app purchases available');

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          debugPrint('💎 Purchase stream error: $error');
        },
      );

      // Query product details
      await _queryProducts();

      // Restore purchases on startup (for returning users)
      await _restorePurchasesInternal();

      _isInitialized = true;
      debugPrint('💎 PurchaseService initialized');
    } catch (e) {
      debugPrint('💎 PurchaseService initialization failed: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated failures
    }
  }

  /// Query available products from the store
  Future<void> _queryProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({premiumProductId});

      if (response.error != null) {
        debugPrint('💎 Query products error: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('💎 No products found for ID: $premiumProductId');
        return;
      }

      _premiumProduct = response.productDetails.first;
      debugPrint('💎 Product found: ${_premiumProduct!.title} - ${_premiumProduct!.price}');
    } catch (e) {
      debugPrint('💎 Failed to query products: $e');
    }
  }

  /// Handle purchase updates from the stream
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('💎 Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('💎 Purchase pending...');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify and deliver the product
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _deliverProduct(purchaseDetails);
          }
          break;

        case PurchaseStatus.error:
          debugPrint('💎 Purchase error: ${purchaseDetails.error?.message}');
          break;

        case PurchaseStatus.canceled:
          debugPrint('💎 Purchase canceled');
          break;
      }

      // Complete the purchase (required for Android)
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('💎 Purchase completed');
      }
    }
  }

  /// Verify the purchase (in production, verify with your server)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // For a one-time purchase without server verification,
    // we trust the store's response
    // In production, you might want to verify with Google Play API

    if (purchaseDetails.productID != premiumProductId) {
      debugPrint('💎 Unknown product ID: ${purchaseDetails.productID}');
      return false;
    }

    return true;
  }

  /// Deliver the product (grant premium access)
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == premiumProductId) {
      await _setPremiumStatus(true);
      debugPrint('💎 Premium access granted!');
    }
  }

  /// Set premium status in SharedPreferences
  Future<void> _setPremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      debugPrint('💎 Premium status set to: $isPremium');
    } catch (e) {
      debugPrint('💎 Failed to set premium status: $e');
    }
  }

  /// Purchase premium (call from UI)
  /// Returns PurchaseResult with error details for user-friendly messages
  Future<PurchaseResult> purchasePremium() async {
    // Debug mode: simulate successful purchase
    if (kDebugMode) {
      debugPrint('💎 [DEBUG] Simulating successful purchase');
      await _setPremiumStatus(true);
      return PurchaseResult.success();
    }

    if (!_isAvailable) {
      debugPrint('💎 Store not available');
      return PurchaseResult.error(
        PurchaseErrorType.storeNotAvailable,
        'Google Play Store is not available on this device',
      );
    }

    if (_premiumProduct == null) {
      debugPrint('💎 Product not loaded, querying...');
      await _queryProducts();
      if (_premiumProduct == null) {
        debugPrint('💎 Product still not available');
        return PurchaseResult.error(
          PurchaseErrorType.productNotFound,
          'Product not found. Please try again later.',
        );
      }
    }

    try {
      // Create purchase param for non-consumable (one-time purchase)
      final purchaseParam = PurchaseParam(
        productDetails: _premiumProduct!,
      );

      // Buy non-consumable (permanent purchase)
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('💎 Purchase initiated: $success');

      if (success) {
        return PurchaseResult.success();
      } else {
        return PurchaseResult.error(
          PurchaseErrorType.purchaseFailed,
          'Could not start purchase. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('💎 Purchase failed: $e');

      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') || errorString.contains('connection')) {
        return PurchaseResult.error(
          PurchaseErrorType.networkError,
          'Network error. Please check your connection.',
        );
      }
      if (errorString.contains('cancel')) {
        return PurchaseResult.error(
          PurchaseErrorType.purchaseCancelled,
          'Purchase was cancelled.',
        );
      }

      return PurchaseResult.error(
        PurchaseErrorType.unknown,
        'Purchase failed: ${e.toString()}',
      );
    }
  }

  /// Internal restore (called on startup)
  Future<void> _restorePurchasesInternal() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('💎 Restore purchases requested');
    } catch (e) {
      debugPrint('💎 Failed to restore purchases: $e');
    }
  }

  /// Restore purchases (call from UI - e.g., settings)
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('💎 Store not available');
      return false;
    }

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('💎 Restore purchases requested');
      return true;
    } catch (e) {
      debugPrint('💎 Failed to restore purchases: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
