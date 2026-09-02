import 'dart:math';
import 'package:geocoding/geocoding.dart';
import '../data/uy_places.dart';

/// Coordenada centinela para "todavía sin resolver": el perfil es de un
/// país sin lista fija (no Uruguay) y no había conexión para geocodificar
/// su ciudad. 0,0 cae en medio del golfo de Guinea — ningún avistamiento
/// real de luciérnagas va a coincidir con eso, así que sirve de marcador
/// inequívoco sin tener que tocar el esquema para admitir NULL. Con
/// Uruguay esto no debería pasar nunca: las coordenadas de la ciudad
/// vienen en `uy_places.dart`, sin depender de la red.
const unresolvedLat = 0.0;
const unresolvedLng = 0.0;

bool isUnresolvedCoordinate(double lat, double lng) =>
    lat == unresolvedLat && lng == unresolvedLng;

/// Convierte un nombre de ciudad en lat/lng (geocodificación directa) —
/// solo hace falta para países fuera de la lista fija de Uruguay.
///
/// Devuelve `null` si no hay conexión, no se encontró la ciudad, o el
/// geocodificador del sistema no está disponible. El resultado se
/// redondea a 3 decimales (~100 m), igual que el resto de coordenadas
/// que maneja la app.
Future<({double lat, double lng})?> forwardGeocodeCity(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return null;
  try {
    // El geocodificador del sistema puede no existir en absoluto en
    // ciertos dispositivos (Android TV sin Play Services completos) y
    // quedarse colgado en vez de lanzar — sin timeout, esto bloqueaba la
    // resolución de la ciudad indefinidamente.
    final locations = await locationFromAddress(trimmed)
        .timeout(const Duration(seconds: 10));
    if (locations.isEmpty) return null;
    final loc = locations.first;
    return (
      lat: double.parse(loc.latitude.toStringAsFixed(3)),
      lng: double.parse(loc.longitude.toStringAsFixed(3)),
    );
  } catch (_) {
    return null;
  }
}

/// Coordenadas de la ciudad del perfil: instantáneas y sin red si es de
/// la lista fija de Uruguay; geocodificadas (necesitan conexión) para
/// cualquier otro país. Es la base sobre la que se calcula el punto
/// aleatorio cuando el usuario no comparte su GPS.
Future<({double lat, double lng})?> resolveProfileCityCoordinates({
  required String country,
  required String city,
}) async {
  if (country == 'Uruguay') {
    final match = findUruguayCity(city);
    if (match != null) return (lat: match.lat, lng: match.lng);
  }
  return forwardGeocodeCity('$city, $country');
}

final _random = Random();

/// Punto al azar dentro de un radio de [radiusKm] alrededor de (lat, lng)
/// — es la alternativa cuando el usuario no comparte su ubicación exacta.
/// `sqrt(u)` en vez de `u` reparte los puntos de forma pareja por área en
/// vez de amontonarlos cerca del centro (un radio al azar sin la raíz
/// concentra la densidad en el medio, porque el área de cada anillo crece
/// con el radio). 111.32 km ≈ 1° de latitud en cualquier punto de la
/// Tierra; para longitud ese mismo grado equivale a menos distancia según
/// te alejas del ecuador, de ahí el `cos(lat)`.
({double lat, double lng}) randomPointNear(double lat, double lng, {double radiusKm = 3}) {
  final angle = _random.nextDouble() * 2 * pi;
  final distanceKm = radiusKm * sqrt(_random.nextDouble());

  const kmPerDegreeLat = 111.32;
  final kmPerDegreeLng = kmPerDegreeLat * cos(lat * pi / 180);

  final dLat = (distanceKm * sin(angle)) / kmPerDegreeLat;
  final dLng = (distanceKm * cos(angle)) / kmPerDegreeLng;

  return (
    lat: double.parse((lat + dLat).toStringAsFixed(3)),
    lng: double.parse((lng + dLng).toStringAsFixed(3)),
  );
}
