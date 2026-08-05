import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sighting_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';

class SightingsState {
  final List<SightingModel> sightings;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const SightingsState({
    this.sightings = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  /// `error` no lleva `??` sobre el valor previo: con eso, pasar `error:
  /// null` para limpiar un error puesto antes no lo limpiaba — el mismo
  /// bug que en ChaptersState/MissionsState.
  SightingsState copyWith({
    List<SightingModel>? sightings,
    bool? isLoading,
    bool? isSubmitting,
    Object? error = _unset,
  }) => SightingsState(
    sightings: sightings ?? this.sightings,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: identical(error, _unset) ? this.error : error as String?,
  );
}

const _unset = Object();

class SightingsNotifier extends StateNotifier<SightingsState> {
  SightingsNotifier(this._ref) : super(const SightingsState()) {
    loadSightings();
  }

  final Ref _ref;

  Future<void> loadSightings() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.mySightings,
      );
      final List data = response.data!['sightings'] as List;
      final List<SightingModel> sightings = data
          .map<SightingModel>((j) => SightingModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(sightings: sightings, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String> submitSighting({
    required double lat,
    required double lng,
    required int quantity,
    String? notes,
    String? photoUrl,
    String? locationName,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    final sighting = SightingModel(
      lat: lat,
      lng: lng,
      quantity: quantity,
      notes: notes,
      photoUrl: photoUrl,
      locationName: locationName,
      isPending: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await _ref.read(apiClientProvider).post(
        ApiEndpoints.sightings,
        data: {
          'lat': lat,
          'lng': lng,
          'quantity': quantity,
          'notes': notes,
          'photo_url': photoUrl,
          'location_name': locationName,
        },
      );
      // Add to local list without pending flag
      final synced = sighting.copyWith(isPending: false);
      state = state.copyWith(
        sightings: [synced, ...state.sightings],
        isSubmitting: false,
      );
      return 'success';
    } catch (_) {
      // Queue for offline sync
      await LocalStorage.instance.queueSighting(sighting.toJson());
      state = state.copyWith(
        sightings: [sighting, ...state.sightings],
        isSubmitting: false,
      );
      return 'pending';
    }
  }
}

final sightingsProvider =
    StateNotifierProvider<SightingsNotifier, SightingsState>(
  (ref) => SightingsNotifier(ref),
);
