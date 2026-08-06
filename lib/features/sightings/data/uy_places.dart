/// Países y ciudades para el selector de ubicación del perfil
/// (`location_setup_screen.dart`). Con Uruguay, la ciudad es un
/// desplegable cerrado con coordenadas ya incluidas — sin depender de la
/// red ni de que un niño escriba bien el nombre. Con cualquier otro país,
/// la ciudad pasa a texto libre resuelto por `forwardGeocodeCity`.
library;

class CountryOption {
  final String name;
  final bool hasFixedCities;
  const CountryOption(this.name, {this.hasFixedCities = false});
}

class CityOption {
  final String name;
  final double lat;
  final double lng;
  const CityOption(this.name, this.lat, this.lng);
}

const countries = [
  CountryOption('Uruguay', hasFixedCities: true),
  CountryOption('Argentina'),
  CountryOption('Brasil'),
  CountryOption('Paraguay'),
  CountryOption('Chile'),
  CountryOption('Otro'),
];

/// Las 19 capitales departamentales, coordenadas verificadas (no de
/// memoria) contra geodatos.net al momento de escribir esto.
const uruguayCities = [
  CityOption('Artigas', -30.40431, -56.46926),
  CityOption('Canelones', -34.52381, -56.28215),
  CityOption('Melo', -32.3682, -54.16409),
  CityOption('Colonia del Sacramento', -34.46262, -57.83976),
  CityOption('Durazno', -33.38063, -56.52312),
  CityOption('Trinidad', -33.5165, -56.89957),
  CityOption('Florida', -34.10032, -56.21477),
  CityOption('Minas', -34.37589, -55.23771),
  CityOption('Maldonado', -34.89791, -54.95021),
  CityOption('Montevideo', -34.90328, -56.18816),
  CityOption('Paysandú', -32.3171, -58.08072),
  CityOption('Fray Bentos', -33.11651, -58.31067),
  CityOption('Rivera', -30.90534, -55.55076),
  CityOption('Rocha', -34.47995, -54.33064),
  CityOption('Salto', -31.38811, -57.95983),
  CityOption('San José de Mayo', -34.33898, -56.71339),
  CityOption('Mercedes', -33.2524, -58.03047),
  CityOption('Tacuarembó', -31.71882, -55.97925),
  CityOption('Treinta y Tres', -33.231, -54.38577),
];

CityOption? findUruguayCity(String name) {
  for (final c in uruguayCities) {
    if (c.name == name) return c;
  }
  return null;
}
