import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_capabilities.dart';

/// Se sobrescribe en `main.dart` con el valor ya resuelto antes de
/// `runApp` (`ProviderScope(overrides: [...])`) — ningún `build()` espera
/// un `Future` para saber si hay cámara o GPS. El valor por defecto aquí
/// (`DeviceCapabilities.fallback`) solo se usa si algún test monta un
/// widget sin pasar por ese override.
final deviceCapabilitiesProvider =
    Provider<DeviceCapabilities>((ref) => DeviceCapabilities.fallback);
