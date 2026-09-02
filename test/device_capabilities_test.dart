import 'package:flutter_test/flutter_test.dart';
import 'package:luchi/core/device/device_capabilities.dart';

/// `DeviceCapabilities` es la base de toda la degradación elegante
/// (sin cámara, sin GPS, Android TV) — si su lógica de clasificación por
/// tamaño o su valor por defecto se rompen, se rompe en silencio en todos
/// los sitios que lo consumen. Ver device_capabilities.dart.
void main() {
  group('DeviceCapabilities.fallback', () {
    test('todo hardware disponible salvo televisor', () {
      const caps = DeviceCapabilities.fallback;
      expect(caps.hasCamera, isTrue);
      expect(caps.hasGps, isTrue);
      expect(caps.hasNetworkLocation, isTrue);
      expect(caps.hasMicrophone, isTrue);
      expect(caps.hasTouchscreen, isTrue);
      expect(caps.hasPlayServices, isTrue);
      expect(caps.isTelevision, isFalse);
    });

    test('un fallo del canal nativo nunca oculta nada en un teléfono', () {
      // shortestSide 0 (no se pudo medir) debe seguir clasificando como
      // teléfono, no como tablet/escritorio — el caso principal de la app
      // no debe perder ninguna función por un fallo de lectura.
      const caps = DeviceCapabilities.fallback;
      expect(caps.isPhone, isTrue);
      expect(caps.isTablet, isFalse);
      expect(caps.isDesktopLike, isFalse);
      expect(caps.supportsPointer, isTrue);
    });
  });

  group('Clasificación por tamaño', () {
    test('lado corto de teléfono', () {
      final caps = DeviceCapabilities.fallback.copyWith(shortestSide: 390);
      expect(caps.isPhone, isTrue);
      expect(caps.isTablet, isFalse);
      expect(caps.isDesktopLike, isFalse);
    });

    test('lado corto de tablet', () {
      final caps = DeviceCapabilities.fallback.copyWith(shortestSide: 700);
      expect(caps.isTablet, isTrue);
      expect(caps.isPhone, isFalse);
      expect(caps.isDesktopLike, isFalse);
    });

    test('lado corto de escritorio/TV', () {
      final caps = DeviceCapabilities.fallback.copyWith(shortestSide: 1080);
      expect(caps.isDesktopLike, isTrue);
      expect(caps.isPhone, isFalse);
      expect(caps.isTablet, isFalse);
    });
  });

  group('supportsPointer', () {
    test('un televisor con touchscreen "fake" no cuenta como puntero real', () {
      const caps = DeviceCapabilities(
        hasCamera: false,
        hasGps: false,
        hasNetworkLocation: false,
        hasMicrophone: false,
        hasTouchscreen: true, // algunos TV declaran fake-touch
        isTelevision: true,
        hasPlayServices: true,
        shortestSide: 1080,
      );
      expect(caps.supportsPointer, isFalse);
    });
  });

  group('hasAnyLocation', () {
    test('falso cuando no hay ni GPS ni ubicación por red', () {
      const caps = DeviceCapabilities(
        hasCamera: true,
        hasGps: false,
        hasNetworkLocation: false,
        hasMicrophone: true,
        hasTouchscreen: true,
        isTelevision: false,
        hasPlayServices: true,
        shortestSide: 390,
      );
      expect(caps.hasAnyLocation, isFalse);
    });
  });
}
