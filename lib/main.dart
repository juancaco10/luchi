import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  // hace falta bloquear el arranque de la app por esto.
  if (AppConstants.adsEnabled) {
    unawaited(MobileAds.instance.initialize());
  }

  runApp(
    const ProviderScope(
      child: GuardianesApp(),
    ),
  );
}
