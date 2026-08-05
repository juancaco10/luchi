import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../utils/constants.dart';

/// Resultado de [loadCachedList]. No oculta un fallo detrás de datos que
/// parecen normales: si `isStale` es true, lo que hay en `items` no vino de
/// la red esta vez — es caché o (solo con `AppConstants.allowSeedData`)
/// datos de ejemplo — y `error` lleva el motivo, aunque la lista no esté
/// vacía.
class LoadResult<T> {
  const LoadResult(this.items, {this.isStale = false, this.error});

  final List<T> items;
  final bool isStale;
  final AppException? error;
}

/// Absorbe el algoritmo "pide a la API, cachea si sale bien, si falla usa
/// caché, y si tampoco hay caché usa datos de ejemplo" — repetido antes
/// carácter por carácter entre `chapters_provider.dart` y
/// `missions_provider.dart`.
///
/// `seed` solo se sirve si `AppConstants.allowSeedData` está activo (false
/// en release por defecto): son datos de ejemplo con vídeos de muestra de
/// Google, no contenido real, y no deben aparecer en producción como si lo
/// fueran ante un fallo de red cualquiera.
Future<LoadResult<T>> loadCachedList<T>({
  required ApiClient api,
  required String path,
  required String envelopeKey,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required List<Map<String, dynamic>> Function() readCache,
  required Future<void> Function(List<Map<String, dynamic>>) writeCache,
  List<T> Function()? seed,
}) async {
  try {
    final response = await api.get<Map<String, dynamic>>(path);
    final List data = response.data![envelopeKey] as List;
    final items =
        data.map<T>((j) => fromJson(j as Map<String, dynamic>)).toList();
    await writeCache(items.map(toJson).toList());
    return LoadResult(items);
  } on DioException catch (e) {
    final err = e.error is AppException
        ? e.error as AppException
        : AppException(e.message ?? 'Error de red', e.response?.statusCode);

    final cachedRaw = readCache();
    if (cachedRaw.isNotEmpty) {
      return LoadResult(
        cachedRaw.map(fromJson).toList(),
        isStale: true,
        error: err,
      );
    }

    if (AppConstants.allowSeedData && seed != null) {
      final seeded = seed();
      if (seeded.isNotEmpty) {
        return LoadResult(seeded, isStale: true, error: err);
      }
    }

    return LoadResult(const [], isStale: true, error: err);
  }
}
