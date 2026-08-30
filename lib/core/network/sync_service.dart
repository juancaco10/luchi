import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import '../storage/local_storage.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/sightings/providers/sightings_provider.dart';
import '../../features/sightings/utils/sighting_geocoding.dart';

class SyncService {
  final Ref _ref;
  StreamSubscription? _sub;
  bool _isSyncing = false;

  SyncService(this._ref) {
    start();
  }

  void start() {
    // Antes solo se sincronizaba al *cambiar* de conectividad: si la app
    // arrancaba ya con internet y quedaban avistamientos pendientes de la
    // sesión anterior, nunca se drenaban hasta el siguiente cambio de red.
    _syncPending();

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus 6.x siempre emite List<ConnectivityResult>.
      if (!results.contains(ConnectivityResult.none)) _syncPending();
    });
  }

  void stop() {
    _sub?.cancel();
  }

  Future<void> _syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingSightings = LocalStorage.instance.getPendingSightingsWithKeys();
      if (pendingSightings.isEmpty) return;

      bool anySuccess = false;
      bool sightingsSynced = false;

      // Borrado por clave individual tras cada éxito: si la app muere a
      // mitad de la sincronización, solo se pierden reintentos, no
      // avistamientos ya subidos ni los que aún no se intentaron.
      for (final entry in pendingSightings.entries) {
        final sighting = entry.value;
        try {
          // Caso raro pero posible: perfil de un país sin lista fija (no
          // Uruguay) que registró sin conexión, así que ni el GPS ni el
          // punto aleatorio tenían de dónde sacar la ciudad y quedó con la
          // coordenada centinela (ver sighting_geocoding.dart). Ahora que
          // sí hay conexión, se resuelve justo antes de subirlo.
          var lat = (sighting['lat'] as num).toDouble();
          var lng = (sighting['lng'] as num).toDouble();
          final locationName = sighting['location_name'] as String?;

          if (isUnresolvedCoordinate(lat, lng) &&
              locationName != null &&
              locationName.trim().isNotEmpty) {
            final resolved = await forwardGeocodeCity(locationName);
            if (resolved != null) {
              lat = resolved.lat;
              lng = resolved.lng;
            }
            // Si sigue sin resolverse (ciudad no encontrada, no solo sin
            // conexión), se sube igual con la centinela — se puede
            // corregir editando el avistamiento — en vez de bloquear la
            // sincronización del resto de la cola indefinidamente.
          }

          await _ref.read(apiClientProvider).post(
            ApiEndpoints.sightings,
            data: {
              'lat': lat,
              'lng': lng,
              'quantity': sighting['quantity'],
              'notes': sighting['notes'],
              'photo_url': sighting['photo_url'],
              'location_name': locationName,
            },
          );
          await LocalStorage.instance.removePendingSighting(entry.key);
          anySuccess = true;
          sightingsSynced = true;
        } catch (_) {
          // Se queda en la caja para el próximo intento.
        }
      }

      // El avistamiento pendiente vivía en el estado en memoria marcado
      // `isPending: true` desde que se creó offline; sin esto, aunque ya
      // se subiera bien (con su ciudad/país resuelto arriba), la lista
      // seguiría mostrándolo como pendiente hasta reiniciar la app.
      if (sightingsSynced) {
        _ref.read(sightingsProvider.notifier).loadSightings();
        // El mapa pinta el feed comunitario: si ya estaba abierto cuando
        // vuelve la conexión, refrescarlo aquí hace que el avistamiento
        // subido ahora aparezca sin reiniciar la app.
        _ref.read(sightingsProvider.notifier).loadCommunitySightings();
      }

      if (anySuccess) {
        // Refresh user profile to reflect the new points from synced sightings
        _ref.read(authProvider.notifier).refreshSession();
      }
    } finally {
      _isSyncing = false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(() => service.stop());
  return service;
});
