import 'dart:io';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

/// Filtro de contenido 100% on-device: la imagen se clasifica en el propio
/// teléfono (TFLite en Android, Core ML en iOS) y nunca sale del
/// dispositivo para esta comprobación — ni se manda a un servicio externo
/// ni pasa por nuestro backend.
///
/// Es una primera barrera, no un moderador perfecto: un modelo tan ligero
/// (~22 MB) tiene más falsos positivos/negativos que uno grande en la
/// nube. Bloquea lo obvio antes de que la foto se suba; no sustituye una
/// revisión humana si en el futuro hay reportes de contenido.
///
/// Devuelve `true` si la foto se puede usar. Ante cualquier fallo de la
/// clasificación (modelo no disponible, imagen no decodificable, etc.) se
/// deja pasar la foto — un fallo del clasificador no debe bloquear el uso
/// normal de la app.
Future<bool> isPhotoSafe(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final result = await NsfwDetector.detectBytesInBackground(bytes, threshold: 0.7);
    if (result == null) return true;
    return !result.isNsfw;
  } catch (_) {
    return true;
  }
}
