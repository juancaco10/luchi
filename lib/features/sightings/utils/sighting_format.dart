import '../models/sighting_model.dart';

/// "5 min", "3 h", "2 d" — formato compacto a propósito: en la tarjeta del
/// home comparte fila con el chip de la ciudad dentro de 135 px, y el
/// "hace " de más le robaba ancho al nombre del lugar. Sin paquete de i18n
/// de fechas solo para esto. Compartido entre el home y "Mis avistamientos".
String relativeTime(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  return '${diff.inDays} d';
}

/// La ciudad es obligatoria desde el formulario, así que este fallback
/// solo se ve en un dato antiguo sin nombre — nunca coordenadas crudas.
String sightingLocationLabel(SightingModel s) {
  return s.locationName?.trim().isNotEmpty == true
      ? s.locationName!
      : 'Ubicación sin nombre';
}
