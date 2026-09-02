import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/device/device_capabilities_provider.dart';
import '../core/utils/constants.dart';

/// Banner de anuncios fijo, pensado para ir en `bottomNavigationBar` (encima
/// del menú inferior o al pie de una pantalla sin él).
///
/// Mientras el anuncio no terminó de cargar (o falló) ocupa cero espacio en
/// vez de mostrar un hueco gris — así una falla de red no dejaría un
/// rectángulo vacío pegado al menú, y el layout no salta cuando sí carga
/// porque el tamaño ya viene fijado por `AdSize` antes de pedirlo.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // AdMob no sirve inventario a televisores; se evita además la llamada
    // de red que nunca va a devolver un anuncio.
    final isTelevision = ref.read(deviceCapabilitiesProvider).isTelevision;
    if (AppConstants.adsEnabled && !isTelevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  // kIsWeb primero: `Platform.isIOS` (dart:io) lanza en web, donde no hay
  // banner (AdBanner no se monta en web hoy, pero esto lo deja seguro si
  // algún día se activa ahí sin tener que recordar este detalle).
  String get _adUnitId => (!kIsWeb && Platform.isIOS)
      ? AppConstants.adBannerUnitIdIOS
      : AppConstants.adBannerUnitIdAndroid;

  Future<void> _load() async {
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width);

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
    } on Object catch (_) {
      // SDK no inicializado, sin Play Services, o cualquier otro fallo de
      // plataforma: el banner se queda oculto (build() ya lo resuelve),
      // no debe tirar abajo la pantalla que lo contiene.
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
