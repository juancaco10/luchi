import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/device/device_capabilities.dart';
import 'core/device/device_capabilities_provider.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resuelto una sola vez, antes de runApp, e inyectado por
  // ProviderScope.overrides — ver device_capabilities.dart. Nunca falla:
  // DeviceCapabilitiesReader ya degrada a DeviceCapabilities.fallback
  // ante cualquier error de plataforma.
  final deviceCapabilities = await const DeviceCapabilitiesReader().read();

  // Lock to portrait mode for better children UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize local storage
  await LocalStorage.instance.init();

  // Sin await: el banner (lib/widgets/ad_banner.dart) espera a que el SDK
  // esté listo por su cuenta antes de cargar el primer anuncio, así que no
  // hace falta bloquear el arranque de la app por esto. No se monta en TV
  // (AdMob no sirve inventario a televisores) y el try/catch evita un
  // error asíncrono no capturado si faltan Google Play Services.
  if (AppConstants.adsEnabled && !deviceCapabilities.isTelevision) {
    unawaited(_initAdsSafely());
  }

  runApp(
    ProviderScope(
      overrides: [
        deviceCapabilitiesProvider.overrideWithValue(deviceCapabilities),
      ],
      child: const GuardianesApp(),
    ),
  );
}

/// `MobileAds.instance.initialize()` puede rechazar el Future (Google Play
/// Services ausente o desactualizado) — sin este try/catch, el `unawaited`
/// de arriba dejaba ese rechazo como un error asíncrono no capturado.
Future<void> _initAdsSafely() async {
  try {
    await MobileAds.instance.initialize();
  } on Object catch (_) {
    // El banner ya degrada solo (ver ad_banner.dart): si el SDK no
    // arrancó, _load() falla por su cuenta y el banner queda oculto.
  }
}
