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
      final pending = LocalStorage.instance.getPendingSightings();
      if (pending.isEmpty) return;

      bool anySuccess = false;

      // Important: if we remove items we should update the storage. 
      // It's safer to clear the box and re-insert the failed ones.
      final List<Map<String, dynamic>> failed = [];

      for (final sighting in pending) {
        try {
          await ApiClient.instance.post(
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
          anySuccess = true;
        } catch (_) {
          failed.add(sighting);
        }
      }

      await LocalStorage.instance.clearPendingSightings();
      for (final f in failed) {
        await LocalStorage.instance.queueSighting(f);
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
