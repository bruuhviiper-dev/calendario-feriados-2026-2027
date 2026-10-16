import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob completo (Android/iOS): banner, intersticial, app-open e premiado.
/// Usa IDs de TESTE (fase de testes). Na publicação, troque `_useTestAds` para
/// false e preencha os IDs reais. NUNCA clique nos próprios anúncios reais.
class AdsService with WidgetsBindingObserver {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const bool _useTestAds = false;

  // IDs de TESTE oficiais do Google
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';

  // IDs reais (app31 Frases para Refletir — conta AdMob 5880219350817278)
  static const _realBanner = 'ca-app-pub-5880219350817278/1690432673';
  static const _realInterstitial = 'ca-app-pub-5880219350817278/5506719290';
  static const _realRewarded = 'ca-app-pub-5880219350817278/2580490866';
  static const _realAppOpen = 'ca-app-pub-5880219350817278/9470015032';
  static bool _ph(String id) => id.contains('0000000000');

  bool _initialized = false;
  bool get _supported => Platform.isAndroid || Platform.isIOS;

  /// Setado pelo banner (lê o AppState): usuário pagante não vê anúncios.
  bool adsRemoved = false;

  /// Intersticial e app-open LIGADOS, com throttle (intervalo mínimo entre
  /// exibições) pra não atrapalhar a usabilidade.
  bool interstitialEnabled = true;
  bool appOpenEnabled = true;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  AppOpenAd? _appOpenAd;
  DateTime? _lastAppOpenShown;
  bool _showingFullScreenAd = false;

  static const int interstitialEvery = 6;
  int _actionsSinceLastAd = 0;
  DateTime? _lastInterstitialShown;

  String get bannerUnitId =>
      (_useTestAds || _ph(_realBanner)) ? _testBanner : _realBanner;
  String get _interstitialUnitId =>
      (_useTestAds || _ph(_realInterstitial)) ? _testInterstitial : _realInterstitial;
  String get _rewardedUnitId =>
      (_useTestAds || _ph(_realRewarded)) ? _testRewarded : _realRewarded;
  String get _appOpenUnitId =>
      (_useTestAds || _ph(_realAppOpen)) ? _testAppOpen : _realAppOpen;

  void init() {
    if (_initialized || !_supported) return;
    _initialized = true;
    MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    if (interstitialEnabled) _preloadInterstitial();
    if (appOpenEnabled) _loadAppOpen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) maybeShowAppOpen();
  }

  // ----- Premiado -----
  Future<bool> showRewarded(void Function() onReward) async {
    if (!_supported) {
      onReward();
      return true;
    }
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
            onAdDismissedFullScreenContent: (ad) {
              _showingFullScreenAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              _showingFullScreenAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            earned = true;
            onReward();
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded falhou: $err');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  // ----- Intersticial -----
  void _preloadInterstitial() {
    if (!_supported || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Conta uma ação relevante e exibe o intersticial ao atingir o limite
  /// (intervalo mínimo de 60s). Não exibe pra quem removeu anúncios.
  void registerActionAndMaybeShow() {
    if (!interstitialEnabled) return;
    if (!_supported || adsRemoved || _showingFullScreenAd) return;
    _actionsSinceLastAd++;
    if (_actionsSinceLastAd < interstitialEvery) return;
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < const Duration(seconds: 60)) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreenAd = false;
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _showingFullScreenAd = false;
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
    _actionsSinceLastAd = 0;
    _lastInterstitialShown = now;
  }

  // ----- App Open -----
  void _loadAppOpen() {
    if (!_supported || _appOpenAd != null) return;
    AppOpenAd.load(
      adUnitId: _appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (err) => _appOpenAd = null,
      ),
    );
  }

  void maybeShowAppOpen() {
    if (!appOpenEnabled) return;
    if (!_supported || adsRemoved || _showingFullScreenAd) return;
    final now = DateTime.now();
    if (_lastAppOpenShown != null &&
        now.difference(_lastAppOpenShown!) < const Duration(minutes: 4)) {
      return;
    }
    // Não emenda app-open logo depois de um intersticial (o resumo dispara
    // ao fechar o intersticial). Evita "anúncio em cima de anúncio".
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < const Duration(seconds: 90)) {
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      _loadAppOpen();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _showingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpen();
      },
    );
    ad.show();
    _appOpenAd = null;
    _lastAppOpenShown = now;
  }
}
