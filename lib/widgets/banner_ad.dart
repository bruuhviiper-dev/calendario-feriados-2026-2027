import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../services/app_state.dart';

/// Banner ADAPTATIVO ancorado do AdMob: ocupa a largura real do device
/// (melhor eCPM que o 320x50 fixo). Some quando o usuário comprou "remover
/// anúncios" / premium. Mantém o nome BannerPlaceholder por compatibilidade.
class BannerPlaceholder extends StatefulWidget {
  const BannerPlaceholder({super.key});

  @override
  State<BannerPlaceholder> createState() => _BannerPlaceholderState();
}

class _BannerPlaceholderState extends State<BannerPlaceholder> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _requested = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!_supported) {
      setState(() => _failed = true);
      return;
    }
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait, width);
    if (size == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final ad = BannerAd(
      size: size,
      adUnitId: AdsService.instance.bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    await ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removed = context.watch<AppState>().adsRemoved;
    AdsService.instance.adsRemoved = removed;
    if (removed || _failed) return const SizedBox.shrink();
    if (_ad == null || !_loaded) return const SizedBox(height: 60);
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}

/// Retângulo médio (300x250) — inserido no meio de conteúdo que rola
/// (lista de feriados). eCPM maior que o banner, sem cobrir a navegação.
/// Some para quem removeu anúncios.
class MediumRectangleAd extends StatefulWidget {
  const MediumRectangleAd({super.key});

  @override
  State<MediumRectangleAd> createState() => _MediumRectangleAdState();
}

class _MediumRectangleAdState extends State<MediumRectangleAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _requested = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      _load();
    }
  }

  void _load() {
    if (!_supported) {
      setState(() => _failed = true);
      return;
    }
    final ad = BannerAd(
      size: AdSize.mediumRectangle,
      adUnitId: AdsService.instance.bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removed = context.watch<AppState>().adsRemoved;
    if (removed || _failed) return const SizedBox.shrink();
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
