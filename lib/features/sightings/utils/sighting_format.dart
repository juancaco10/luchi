import '../models/sighting_model.dart';

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _monthsShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Punto único de parseo de fechas de avistamiento.
///
/// El backend ya manda `created_at` en ISO-8601 UTC explícito
/// (`2026-08-06T21:03:11Z`) — `DateTime.parse` lo reconoce y devuelve un
/// `DateTime` UTC, que `.toLocal()` convierte a la hora del dispositivo.
/// Un avistamiento creado offline usa `DateTime.now().toIso8601String()`
/// (ya local, sin `Z`); `.toLocal()` sobre un `DateTime` que ya es local
/// es un no-op, así que la misma llamada sirve para los dos casos sin
/// tener que distinguirlos aquí.
DateTime? parseSightingDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  return date?.toLocal();
}

/// "ahora", "5 min", "3 h", "2 d", "6 ago" — compacto a propósito: en la
/// tarjeta del home comparte fila con el chip de la ciudad dentro de
/// 135 px. A partir de una semana cambia a fecha corta porque "27 d" deja
/// de ser una unidad que un niño ubique de un vistazo.
String relativeTimeShort(String isoDate) {
  final date = parseSightingDate(isoDate);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} d';
  return '${date.day} ${_monthsShort[date.month - 1]}';
}

/// Alias histórico de [relativeTimeShort] — no romper las llamadas
/// existentes de una vez. Preferir el nombre explícito en código nuevo.
String relativeTime(String isoDate) => relativeTimeShort(isoDate);

/// "hace un momento", "hace 5 minutos", "hace 3 horas", "ayer",
/// "hace 4 días", "el 6 de agosto" — para el modal de detalle, que tiene
/// sitio de sobra y se beneficia de ser legible para un niño de 6–12 años
/// en vez de compacto.
String relativeTimeLong(String isoDate) {
  final date = parseSightingDate(isoDate);
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'hace un momento';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'hace $m minuto${m == 1 ? '' : 's'}';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'hace $h hora${h == 1 ? '' : 's'}';
  }
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(date.year, date.month, date.day);
  if (today.difference(thatDay).inDays == 1) return 'ayer';
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return 'hace $d día${d == 1 ? '' : 's'}';
  }
  final sameYear = date.year == now.year;
  return sameYear
      ? 'el ${date.day} de ${_months[date.month - 1]}'
      : 'el ${date.day} de ${_months[date.month - 1]} de ${date.year}';
}

/// "6 de agosto de 2026, 21:03" — fecha y hora absolutas, para quien
/// quiera saber exactamente cuándo se publicó algo, no solo "hace cuánto".
String absoluteDateTime(String isoDate) {
  final date = parseSightingDate(isoDate);
  if (date == null) return '';
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} de ${_months[date.month - 1]} de ${date.year}, $hh:$mm';
}

/// La ciudad es obligatoria desde el formulario, así que este fallback
/// solo se ve en un dato antiguo sin nombre — nunca coordenadas crudas.
String sightingLocationLabel(SightingModel s) {
  return s.locationName?.trim().isNotEmpty == true
      ? s.locationName!
      : 'Ubicación sin nombre';
}

/// Devuelve solo la primera parte (ciudad) si la ubicación tiene comas.
String sightingShortLocationLabel(SightingModel s) {
  final full = sightingLocationLabel(s);
  if (full.contains(',')) {
    return full.split(',').first.trim();
  }
  return full;
}
