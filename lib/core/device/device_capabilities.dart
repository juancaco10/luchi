import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Qué hardware tiene realmente el dispositivo, resuelto una sola vez al
/// arrancar (ver `main.dart`) y expuesto por `deviceCapabilitiesProvider`
/// (ver `device_capabilities_provider.dart`) — nunca se recalcula pantalla
/// a pantalla.
///
/// Los flags de hardware (`hasCamera`, `hasGps`, ...) vienen del canal
/// nativo `luchi/device_capabilities` (`MainActivity.kt`), que usa
/// `PackageManager.hasSystemFeature` — la misma fuente que usa Google Play
/// para filtrar dispositivos, así que lo que aquí se ve "sin cámara"
/// coincide exactamente con lo que Play ya dejó pasar por el manifiesto
/// (ver los `uses-feature required="false"` en AndroidManifest.xml).
///
/// Los flags de *tamaño* (`isTablet`, `isDesktopLike`) sí se derivan del
/// tamaño de pantalla (`shortestSide`), que es la señal correcta para eso
/// — nunca se usa el tamaño para decidir si hay cámara o GPS, esa es
/// justo la trampa que este archivo evita.
@immutable
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.hasCamera,
    required this.hasGps,
    required this.hasNetworkLocation,
    required this.hasMicrophone,
    required this.hasTouchscreen,
    required this.isTelevision,
    required this.hasPlayServices,
    required this.shortestSide,
  });

  final bool hasCamera;
  final bool hasGps;
  final bool hasNetworkLocation;
  final bool hasMicrophone;
  final bool hasTouchscreen;
  final bool isTelevision;
  final bool hasPlayServices;

  /// Lado más corto de la pantalla en dp, para clasificar el tamaño del
  /// dispositivo. `0` cuando no se pudo leer (p. ej. en un test que no
  /// monta ninguna ventana) — en ese caso `isTablet`/`isDesktopLike` caen
  /// a `false`, que es lo seguro para no cambiar el layout de un teléfono.
  final double shortestSide;

  /// Alguna forma de obtener una posición aproximada sin GPS de precisión.
  bool get hasAnyLocation => hasGps || hasNetworkLocation;

  /// Umbral de Material Design para "tablet": ≥600dp de lado corto.
  bool get isTablet => shortestSide >= 600 && shortestSide < 905;

  /// Escritorio/TV/pantalla grande: bastante más ancho que una tablet.
  bool get isDesktopLike => shortestSide >= 905;

  bool get isPhone => !isTablet && !isDesktopLike;

  /// Hay un puntero real (dedo, ratón) con el que interactuar, no solo
  /// D-pad/mando. Un televisor sin táctil no lo tiene aunque reporte
  /// `hasTouchscreen` (los emuladores de "fake touch" sí lo declaran).
  bool get supportsPointer => hasTouchscreen && !isTelevision;

  /// Valor seguro para cuando el canal nativo falla (plataforma no
  /// Android, plugin no registrado, excepción de plataforma) o para
  /// widget tests que no montan `MethodChannel`. Todo `true` salvo
  /// `isTelevision`: así un fallo del canal nunca oculta una función en
  /// el dispositivo real que sí la tiene — el teléfono, el caso
  /// principal, no pierde nada.
  static const fallback = DeviceCapabilities(
    hasCamera: true,
    hasGps: true,
    hasNetworkLocation: true,
    hasMicrophone: true,
    hasTouchscreen: true,
    isTelevision: false,
    hasPlayServices: true,
    shortestSide: 0,
  );

  DeviceCapabilities copyWith({double? shortestSide}) {
    return DeviceCapabilities(
      hasCamera: hasCamera,
      hasGps: hasGps,
      hasNetworkLocation: hasNetworkLocation,
      hasMicrophone: hasMicrophone,
      hasTouchscreen: hasTouchscreen,
      isTelevision: isTelevision,
      hasPlayServices: hasPlayServices,
      shortestSide: shortestSide ?? this.shortestSide,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceCapabilities &&
      other.hasCamera == hasCamera &&
      other.hasGps == hasGps &&
      other.hasNetworkLocation == hasNetworkLocation &&
      other.hasMicrophone == hasMicrophone &&
      other.hasTouchscreen == hasTouchscreen &&
      other.isTelevision == isTelevision &&
      other.hasPlayServices == hasPlayServices &&
      other.shortestSide == shortestSide;

  @override
  int get hashCode => Object.hash(
        hasCamera,
        hasGps,
        hasNetworkLocation,
        hasMicrophone,
        hasTouchscreen,
        isTelevision,
        hasPlayServices,
        shortestSide,
      );
}

/// Punto único de acceso al canal nativo. Se llama una sola vez desde
/// `main.dart`, antes de `runApp` — nunca desde un `build()`.
class DeviceCapabilitiesReader {
  const DeviceCapabilitiesReader();

  static const _channel = MethodChannel('luchi/device_capabilities');

  Future<DeviceCapabilities> read() async {
    final base = await _readNative();
    return base.copyWith(shortestSide: _readShortestSide());
  }

  Future<DeviceCapabilities> _readNative() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('get');
      if (raw == null) return DeviceCapabilities.fallback;
      return DeviceCapabilities(
        hasCamera: raw['hasCamera'] as bool? ?? true,
        hasGps: raw['hasGps'] as bool? ?? true,
        hasNetworkLocation: raw['hasNetworkLocation'] as bool? ?? true,
        hasMicrophone: raw['hasMicrophone'] as bool? ?? true,
        hasTouchscreen: raw['hasTouchscreen'] as bool? ?? true,
        isTelevision: raw['isTelevision'] as bool? ?? false,
        hasPlayServices: raw['hasPlayServices'] as bool? ?? true,
        shortestSide: 0,
      );
    } on Object catch (_) {
      // Plataforma sin el canal (web, iOS, desktop) o cualquier fallo de
      // plataforma: nunca debe bloquear el arranque de la app.
      return DeviceCapabilities.fallback;
    }
  }

  double _readShortestSide() {
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isEmpty) return 0;
      final view = views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      return size.shortestSide;
    } on Object catch (_) {
      return 0;
    }
  }
}
