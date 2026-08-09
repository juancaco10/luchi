import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sighting_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';

class SightingsState {
  final List<SightingModel> sightings;
  final List<SightingModel> archivedSightings;

  /// Feed comunitario (`GET /sightings`): avistamientos ajenos ya
  /// aprobados por moderación, sin nombre de autor. Separado de
  /// `sightings` por la misma razón que los archivados viven aparte: son
  /// datos de naturaleza distinta, no una vista filtrada de lo mismo.
  final List<SightingModel> communitySightings;
  final bool isLoading;
  final bool isSubmitting;
  final bool isLoadingCommunity;
  final String? error;

  const SightingsState({
    this.sightings = const [],
    this.archivedSightings = const [],
    this.communitySightings = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isLoadingCommunity = false,
    this.error,
  });

  /// `error` no lleva `??` sobre el valor previo: con eso, pasar `error:
  /// null` para limpiar un error puesto antes no lo limpiaba — el mismo
  /// bug que en ChaptersState.
  SightingsState copyWith({
    List<SightingModel>? sightings,
    List<SightingModel>? archivedSightings,
    List<SightingModel>? communitySightings,
    bool? isLoading,
    bool? isSubmitting,
    bool? isLoadingCommunity,
    Object? error = _unset,
  }) => SightingsState(
    sightings: sightings ?? this.sightings,
    archivedSightings: archivedSightings ?? this.archivedSightings,
    communitySightings: communitySightings ?? this.communitySightings,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isLoadingCommunity: isLoadingCommunity ?? this.isLoadingCommunity,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.mySightings,
      );
      final List data = response.data!['sightings'] as List;
      final List<SightingModel> apiSightings = data
          .map<SightingModel>((j) => SightingModel.fromJson(j as Map<String, dynamic>))
          .toList();

      final pendingData = LocalStorage.instance.getPendingSightings();
      final List<SightingModel> pendingSightings = pendingData
          .map<SightingModel>((j) => SightingModel.fromJson(j))
          .toList();

      state = state.copyWith(
        sightings: [...pendingSightings, ...apiSightings],
        isLoading: false,
      );
    } on DioException catch (e) {
      // Fallo de red o del servidor: no dejar el mapa en silencio. Se
      // mantiene visible lo que haya en la cola local (pendientes offline)
      // y se expone el motivo para que la pantalla pueda mostrarlo con
      // opción de reintentar — un mapa vacío sin explicación parecía
      // "perder" los avistamientos al reiniciar la app.
      final message = e.error is AppException
          ? (e.error as AppException).message
          : 'No se pudo cargar tus avistamientos.';
      final pendingData = LocalStorage.instance.getPendingSightings();
      final pendingSightings = pendingData
          .map<SightingModel>((j) => SightingModel.fromJson(j))
          .toList();
      state = state.copyWith(
        sightings: pendingSightings,
        isLoading: false,
        error: message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo cargar tus avistamientos.',
      );
    }
  }

  /// Los archivados se piden aparte (`?archived=1`) y solo cuando la
  /// pantalla de archivados los necesita — no en cada `loadSightings()`.
  Future<void> loadArchivedSightings() async {
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.mySightings,
        queryParameters: {'archived': '1'},
      );
      final List data = response.data!['sightings'] as List;
      final List<SightingModel> archived = data
          .map<SightingModel>((j) => SightingModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(archivedSightings: archived);
    } catch (_) {
      // Silencioso: es una lista secundaria, no bloquea la pantalla.
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
      // El mapa muestra el feed comunitario: refrescarlo aquí hace que el
      // avistamiento recién creado aparezca sin reiniciar la app (aunque el
      // mapa ya esté abierto en una pestaña).
      unawaited(loadCommunitySightings());
      return 'success';
    } on DioException catch (e) {
      if (e.response != null) {
        // El servidor respondió con un error (validación, sesión...): NO es
        // falta de conexión. Encolarlo en local sería mentirle al niño —
        // parecería guardado y desaparecería al reinstalar la app. Se
        // expone el error y no se marca como pendiente.
        final message = e.error is AppException
            ? (e.error as AppException).message
            : 'No se pudo guardar el avistamiento. Inténtalo de nuevo.';
        state = state.copyWith(isSubmitting: false, error: message);
        return 'error';
      }
      // Sin respuesta del servidor = sin conexión: se encola y se mostrará
      // como pendiente hasta que la cola offline la suba.
      await LocalStorage.instance.queueSighting(sighting.toJson());
      state = state.copyWith(
        sightings: [sighting, ...state.sightings],
        isSubmitting: false,
      );
      return 'pending';
    } catch (_) {
      // Cualquier otro fallo (p. ej. Hive al encolar) tampoco debe parecer
      // un guardado exitoso.
      await LocalStorage.instance.queueSighting(sighting.toJson());
      state = state.copyWith(
        sightings: [sighting, ...state.sightings],
        isSubmitting: false,
      );
      return 'pending';
    }
  }

  /// Editar un avistamiento existente. Requiere conexión — a diferencia de
  /// `submitSighting`, no se encola: el registro ya existe en el servidor
  /// y no hay forma de "reintentar una edición" sin arriesgar pisar un
  /// cambio posterior. No otorga puntos: editar no es un logro nuevo.
  Future<bool> updateSighting({
    required int id,
    required double lat,
    required double lng,
    required int quantity,
    String? notes,
    String? photoUrl,
    String? locationName,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _ref.read(apiClientProvider).put(
        ApiEndpoints.sighting(id),
        data: {
          'lat': lat,
          'lng': lng,
          'quantity': quantity,
          'notes': notes,
          'photo_url': photoUrl,
          'location_name': locationName,
        },
      );
      final updated = state.sightings.map((s) {
        if (s.id != id) return s;
        return s.copyWith(
          lat: lat,
          lng: lng,
          quantity: quantity,
          notes: notes,
          photoUrl: photoUrl,
          locationName: locationName,
        );
      }).toList();
      state = state.copyWith(sightings: updated, isSubmitting: false);
      return true;
    } on DioException catch (e) {
      final message = e.error is AppException
          ? (e.error as AppException).message
          : 'No se pudo guardar el cambio.';
      state = state.copyWith(isSubmitting: false, error: message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'No se pudo guardar el cambio.',
      );
      return false;
    }
  }

  /// Archiva o desarchiva. Optimista con reversión: la tarjeta desaparece
  /// (o reaparece) de inmediato, y si la llamada falla se revierte y se
  /// expone el error para que la pantalla lo muestre.
  Future<bool> setArchived(int id, bool archived) async {
    final sighting = state.sightings.firstWhere(
      (s) => s.id == id,
      orElse: () => state.archivedSightings.firstWhere((s) => s.id == id),
    );

    if (archived) {
      state = state.copyWith(
        sightings: state.sightings.where((s) => s.id != id).toList(),
        archivedSightings: [
          sighting.copyWith(archivedAt: DateTime.now().toIso8601String()),
          ...state.archivedSightings,
        ],
      );
    } else {
      state = state.copyWith(
        archivedSightings: state.archivedSightings.where((s) => s.id != id).toList(),
        sightings: [sighting.copyWith(archivedAt: null), ...state.sightings],
      );
    }

    try {
      await _ref.read(apiClientProvider).post(
        ApiEndpoints.archiveSighting(id),
        data: {'archived': archived},
      );
      return true;
    } catch (_) {
      // Revertir: deshacer exactamente el movimiento optimista de arriba.
      if (archived) {
        state = state.copyWith(
          archivedSightings: state.archivedSightings.where((s) => s.id != id).toList(),
          sightings: [sighting, ...state.sightings],
        );
      } else {
        state = state.copyWith(
          sightings: state.sightings.where((s) => s.id != id).toList(),
          archivedSightings: [sighting, ...state.archivedSightings],
        );
      }
      state = state.copyWith(
        error: archived
            ? 'No se pudo archivar. Revisa tu conexión.'
            : 'No se pudo desarchivar. Revisa tu conexión.',
      );
      return false;
    }
  }

  /// Carga el feed comunitario. A diferencia de `loadSightings()`, no se
  /// llama en el constructor: solo hace falta cuando alguna pantalla
  /// realmente lo muestra (evita una llamada de red que la mayoría de
  /// sesiones ni usaría, igual que `loadArchivedSightings`).
  Future<void> loadCommunitySightings() async {
    state = state.copyWith(isLoadingCommunity: true);
    try {
      final response = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
        ApiEndpoints.sightings,
      );
      final List data = response.data!['sightings'] as List;
      final List<SightingModel> community = data
          .map<SightingModel>((j) => SightingModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        communitySightings: community,
        isLoadingCommunity: false,
      );
    } on DioException catch (e) {
      final message = e.error is AppException
          ? (e.error as AppException).message
          : 'No se pudo cargar el mapa comunitario.';
      state = state.copyWith(isLoadingCommunity: false, error: message);
    } catch (_) {
      state = state.copyWith(
        isLoadingCommunity: false,
        error: 'No se pudo cargar el mapa comunitario.',
      );
    }
  }

  /// Da o quita el corazón. Optimista con reversión, igual patrón que
  /// `setArchived`: el contador y el estado de "me gusta" cambian al
  /// instante en las tres listas donde el avistamiento pudiera estar (uno
  /// propio puede aparecer también en el feed comunitario si se ve a sí
  /// mismo ahí), y se revierte si la llamada falla.
  Future<bool> toggleLike(int id) async {
    SightingModel? before;
    for (final s in [
      ...state.sightings,
      ...state.communitySightings,
      ...state.archivedSightings,
    ]) {
      if (s.id == id) {
        before = s;
        break;
      }
    }
    if (before == null) return false;

    final liked = !before.likedByMe;
    final delta = liked ? 1 : -1;

    SightingModel apply(SightingModel s) => s.id == id
        ? s.copyWith(likedByMe: liked, likesCount: (s.likesCount + delta).clamp(0, 1 << 30))
        : s;

    state = state.copyWith(
      sightings: state.sightings.map(apply).toList(),
      communitySightings: state.communitySightings.map(apply).toList(),
      archivedSightings: state.archivedSightings.map(apply).toList(),
    );

    try {
      final client = _ref.read(apiClientProvider);
      if (liked) {
        await client.post(ApiEndpoints.likeSighting(id));
      } else {
        await client.delete(ApiEndpoints.likeSighting(id));
      }
      return true;
    } catch (_) {
      SightingModel revert(SightingModel s) => s.id == id ? before! : s;
      state = state.copyWith(
        sightings: state.sightings.map(revert).toList(),
        communitySightings: state.communitySightings.map(revert).toList(),
        archivedSightings: state.archivedSightings.map(revert).toList(),
        error: 'No se pudo guardar tu corazón. Revisa tu conexión.',
      );
      return false;
    }
  }

  /// Sube una foto y devuelve su URL pública ya sin metadatos EXIF (el
  /// servidor la recodifica). Requiere conexión — no se encola.
  Future<String?> uploadPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(file.path),
      });
      final response = await _ref.read(apiClientProvider).uploadFile<Map<String, dynamic>>(
        ApiEndpoints.uploadSightingPhoto,
        formData: formData,
      );
      return response.data?['photo_url'] as String?;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo subir la foto. Revisa tu conexión.');
      return null;
    }
  }
}

final sightingsProvider =
    StateNotifierProvider<SightingsNotifier, SightingsState>(
  (ref) => SightingsNotifier(ref),
);

/// Busca por id en las tres listas (activos, archivados y feed
/// comunitario) — la pantalla de edición puede llegar desde cualquiera de
/// las dos primeras, y el modal de detalle desde cualquiera de las tres.
final sightingByIdProvider = Provider.family<SightingModel?, int>((ref, id) {
  final state = ref.watch(sightingsProvider);
  for (final s in [
    ...state.sightings,
    ...state.archivedSightings,
    ...state.communitySightings,
  ]) {
    if (s.id == id) return s;
  }
  return null;
});
