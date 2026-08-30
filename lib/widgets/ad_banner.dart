import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/utils/constants.dart';

/// Banner de anuncios fijo, pensado para ir en `bottomNavigationBar` (encima
/// del menú inferior o al pie de una pantalla sin él).
///
/// Mientras el anuncio no terminó de cargar (o falló) ocupa cero espacio en
/// vez de mostrar un hueco gris — así una falla de red no dejaría un
/// rectángulo vacío pegado al menú, y el layout no salta cuando sí carga
/// porque el tamaño ya viene fijado por `AdSize` antes de pedirlo.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (AppConstants.adsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  String get _adUnitId => Platform.isIOS
      ? AppConstants.adBannerUnitIdIOS
      : AppConstants.adBannerUnitIdAndroid;

  Future<void> _load() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await ad.load();
    if (mounted) {
      _ad = ad;
    } else {
      ad.dispose();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.adsEnabled) return const SizedBox.shrink();
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
