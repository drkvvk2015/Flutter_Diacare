import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Service for managing ads in DiaCare app
class AdMobService {
  factory AdMobService() => _instance;
  AdMobService._internal();
  static final AdMobService _instance = AdMobService._internal();

  // Your AdMob App ID: ca-app-pub-5849387440690908~8950657162
  
  /// Banner Ad Unit ID
  /// Production: ca-app-pub-5849387440690908/3706548276
  /// Test: ca-app-pub-3940256099942544/6300978111
  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Use test ad unit in debug mode
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // Test banner iOS
      }
    }
    // Production ad unit
    return 'ca-app-pub-5849387440690908/3706548276';
  }

  /// Interstitial Ad Unit ID (create in AdMob if needed)
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // Test interstitial iOS
      }
    }
    // TODO: Add your production interstitial ad unit ID
    return 'ca-app-pub-5849387440690908/XXXXXXXXXX';
  }

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob SDK initialized successfully');
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  /// Load a banner ad
  BannerAd loadBannerAd({
    AdSize size = AdSize.banner,
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );
    
    bannerAd.load();
    _bannerAd = bannerAd;
    return bannerAd;
  }

  /// Load an interstitial ad
  Future<void> loadInterstitialAd({
    void Function(InterstitialAd)? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  /// Show the loaded interstitial ad
  Future<void> showInterstitialAd({
    void Function()? onAdDismissed,
  }) async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not loaded yet');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed?.call();
        // Preload next interstitial
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
      },
    );

    await _interstitialAd!.show();
  }

  /// Dispose banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
  }
}
