import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import '../storage/local_storage.dart';
import '../../features/auth/providers/auth_provider.dart';

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

    _sub = Connectivity().onConnectivityChanged.listen((result) {
      // result is a List<ConnectivityResult> in newer versions of connectivity_plus
      if (result is List<ConnectivityResult>) {
        if (!result.contains(ConnectivityResult.none)) _syncPending();
      } else {
        // Fallback for older versions
        if (result != ConnectivityResult.none) _syncPending();
      }
    });
  }

  void stop() {
    _sub?.cancel();
  }

  Future<void> _syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = LocalStorage.instance.getPendingSightingsWithKeys();
      if (pending.isEmpty) return;

      bool anySuccess = false;

      // Borrado por clave individual tras cada éxito: si la app muere a
      // mitad de la sincronización, solo se pierden reintentos, no
      // avistamientos ya subidos ni los que aún no se intentaron.
      for (final entry in pending.entries) {
        final sighting = entry.value;
        try {
          await _ref.read(apiClientProvider).post(
            ApiEndpoints.sightings,
            data: {
              'lat': sighting['lat'],
              'lng': sighting['lng'],
              'quantity': sighting['quantity'],
              'notes': sighting['notes'],
              'photo_url': sighting['photo_url'],
              'location_name': sighting['location_name'],
            },
          );
          await LocalStorage.instance.removePendingSighting(entry.key);
          anySuccess = true;
        } catch (_) {
          // Se queda en la caja para el próximo intento.
        }
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
