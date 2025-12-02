import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AdService - Singleton service for managing interstitial ads
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// await AdService.instance.initialize();
///
/// // Show ad when saving (if not premium)
/// await AdService.instance.showInterstitialAd();
/// ```
class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isInitialized = false;

  // Ad Unit IDs (Production)
  // Android: ca-app-pub-6737616702687889/4385392169
  // iOS: ca-app-pub-6737616702687889/3204882872
  static const String _androidAdUnitId = 'ca-app-pub-6737616702687889/4385392169';
  static const String _iosAdUnitId = 'ca-app-pub-6737616702687889/3204882872';

  // Test Ad Unit IDs (for development)
  static const String _androidTestAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  /// Get the appropriate ad unit ID based on platform and build mode
  String get _adUnitId {
    if (kDebugMode) {
      // Use test ads in debug mode
      return Platform.isAndroid ? _androidTestAdUnitId : _iosTestAdUnitId;
    }
    // Use production ads in release mode
    return Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;
  }

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request ATT permission on iOS before initializing ads
      if (Platform.isIOS) {
        await _requestTrackingAuthorization();
      }

      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('📺 AdMob initialized successfully');

      // Pre-load an interstitial ad
      await _loadInterstitialAd();
    } catch (e) {
      debugPrint('📺 AdMob initialization failed: $e');
    }
  }

  /// Request App Tracking Transparency (ATT) authorization on iOS
  /// This is required for personalized ads on iOS 14.5+
  Future<void> _requestTrackingAuthorization() async {
    try {
      // Check current status first
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('📺 ATT current status: $status');

      // Only request if not determined yet
      if (status == TrackingStatus.notDetermined) {
        // Small delay to avoid conflicts with other permission dialogs
        // (e.g., notification permission on first launch)
        await Future.delayed(const Duration(milliseconds: 500));

        final newStatus =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('📺 ATT new status after request: $newStatus');
      }
    } catch (e) {
      debugPrint('📺 ATT request failed: $e');
    }
  }

  /// Load an interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint('📺 Interstitial ad loaded');

          // Set up full screen content callback
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('📺 Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load next ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('📺 Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load next ad
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('📺 Interstitial ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Check if user has premium (ad-free) status
  Future<bool> _isPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isPremium') ?? false;
    } catch (e) {
      debugPrint('📺 Failed to check premium status: $e');
      return false;
    }
  }

  /// Show interstitial ad if not premium
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    // Check premium status first
    final isPremium = await _isPremium();
    if (isPremium) {
      debugPrint('📺 User is premium, skipping ad');
      return false;
    }

    // Check if ad is loaded
    if (!_isAdLoaded || _interstitialAd == null) {
      debugPrint('📺 No ad loaded, attempting to load');
      await _loadInterstitialAd();
      return false;
    }

    // Show the ad
    try {
      await _interstitialAd!.show();
      debugPrint('📺 Interstitial ad shown');
      return true;
    } catch (e) {
      debugPrint('📺 Failed to show interstitial ad: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
