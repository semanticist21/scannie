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

  // Completer for waiting on purchase result
  Completer<PurchaseResult>? _purchaseCompleter;

  // Completer for waiting on restore result
  Completer<PurchaseResult>? _restoreCompleter;

  // Premium product ID (matches Play Console configuration)
  static const String premiumProductId = 'premium';

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

      // Log not found IDs for debugging
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('💎 Not found IDs: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        debugPrint('💎 No products found for ID: $premiumProductId');
        debugPrint('💎 Tip: Check license testers in Play Console → Settings → License testing');
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

      // Only handle our product
      if (purchaseDetails.productID != premiumProductId) {
        debugPrint('💎 Ignoring unknown product: ${purchaseDetails.productID}');
        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('💎 Purchase pending...');
          // Don't complete the Completer yet - wait for final status
          break;

        case PurchaseStatus.purchased:
          // Verify and deliver the product
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _deliverProduct(purchaseDetails);
            // Complete the purchase Completer with success
            _completePurchaseCompleter(PurchaseResult.success());
          } else {
            _completePurchaseCompleter(PurchaseResult.error(
              PurchaseErrorType.purchaseFailed,
              'Purchase verification failed',
            ));
          }
          break;

        case PurchaseStatus.restored:
          // Verify and deliver the restored product
          final validRestore = await _verifyPurchase(purchaseDetails);
          if (validRestore) {
            await _deliverProduct(purchaseDetails);
            // Complete the restore Completer with success
            _completeRestoreCompleter(PurchaseResult.success());
          } else {
            _completeRestoreCompleter(PurchaseResult.error(
              PurchaseErrorType.purchaseFailed,
              'Restore verification failed',
            ));
          }
          break;

        case PurchaseStatus.error:
          debugPrint('💎 Purchase error: ${purchaseDetails.error?.message}');
          _completePurchaseCompleter(PurchaseResult.error(
            PurchaseErrorType.purchaseFailed,
            purchaseDetails.error?.message ?? 'Purchase failed',
          ));
          break;

        case PurchaseStatus.canceled:
          debugPrint('💎 Purchase canceled');
          _completePurchaseCompleter(PurchaseResult.error(
            PurchaseErrorType.purchaseCancelled,
            'Purchase was cancelled',
          ));
          break;
      }

      // Complete the purchase transaction (required for all final states)
      // This tells the store to finalize the transaction
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('💎 Purchase transaction completed');
      }
    }
  }

  /// Safely complete the purchase Completer
  void _completePurchaseCompleter(PurchaseResult result) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(result);
      debugPrint('💎 Purchase Completer completed with: ${result.success ? "success" : result.errorType}');
    }
  }

  /// Safely complete the restore Completer
  void _completeRestoreCompleter(PurchaseResult result) {
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(result);
      debugPrint('💎 Restore Completer completed with: ${result.success ? "success" : result.errorType}');
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
  ///
  /// Note: This method waits for the actual purchase result from the store,
  /// not just the initiation of the purchase flow.
  Future<PurchaseResult> purchasePremium() async {
    // [DISABLED FOR TESTING] Debug mode: simulate successful purchase
    // Uncomment below to skip store communication in debug builds
    // if (kDebugMode) {
    //   debugPrint('💎 [DEBUG] Simulating successful purchase');
    //   await _setPremiumStatus(true);
    //   return PurchaseResult.success();
    // }

    if (!_isAvailable) {
      debugPrint('💎 Store not available');
      return PurchaseResult.error(
        PurchaseErrorType.storeNotAvailable,
        'Store is not available on this device',
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

    // Cancel any existing purchase Completer
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(PurchaseResult.error(
        PurchaseErrorType.purchaseCancelled,
        'New purchase started',
      ));
    }

    // Create new Completer to wait for actual purchase result
    _purchaseCompleter = Completer<PurchaseResult>();

    try {
      // Create purchase param for non-consumable (one-time purchase)
      final purchaseParam = PurchaseParam(
        productDetails: _premiumProduct!,
      );

      // Buy non-consumable (permanent purchase)
      // Note: This returns true if the purchase flow was INITIATED, not completed
      final initiated = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('💎 Purchase flow initiated: $initiated');

      if (!initiated) {
        // Purchase flow failed to start
        _purchaseCompleter = null;
        return PurchaseResult.error(
          PurchaseErrorType.purchaseFailed,
          'Could not start purchase. Please try again.',
        );
      }

      // Wait for actual purchase result from the stream
      // Timeout after 5 minutes (in case iOS bug where stream doesn't emit on cancel)
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('💎 Purchase timeout - user may have cancelled without stream emit');
          return PurchaseResult.error(
            PurchaseErrorType.purchaseCancelled,
            'Purchase timed out. Please try again.',
          );
        },
      );

      _purchaseCompleter = null;
      return result;
    } catch (e) {
      debugPrint('💎 Purchase failed: $e');
      _purchaseCompleter = null;

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
  /// Returns PurchaseResult indicating success or failure of restore
  ///
  /// Note: This method waits for the actual restore result from the store,
  /// not just the initiation of the restore flow.
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('💎 Store not available');
      return PurchaseResult.error(
        PurchaseErrorType.storeNotAvailable,
        'Store is not available on this device',
      );
    }

    // Cancel any existing restore Completer
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(PurchaseResult.error(
        PurchaseErrorType.purchaseCancelled,
        'New restore started',
      ));
    }

    // Create new Completer to wait for actual restore result
    _restoreCompleter = Completer<PurchaseResult>();

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('💎 Restore purchases requested');

      // Wait for actual restore result from the stream
      // Timeout after 10 seconds (restore might have no previous purchases)
      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          debugPrint('💎 Restore timeout - checking premium status');
          // Check if premium was restored during the wait
          final isPremiumNow = await isPremium;
          if (isPremiumNow) {
            return PurchaseResult.success();
          }
          // No previous purchases found (not an error, just nothing to restore)
          return PurchaseResult.error(
            PurchaseErrorType.productNotFound,
            'No previous purchases found',
          );
        },
      );

      _restoreCompleter = null;
      return result;
    } catch (e) {
      debugPrint('💎 Failed to restore purchases: $e');
      _restoreCompleter = null;

      return PurchaseResult.error(
        PurchaseErrorType.unknown,
        'Restore failed: ${e.toString()}',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
