import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/education/providers/chapters_provider.dart';
import '../../features/games/providers/games_progress_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/sightings/providers/sightings_provider.dart';

/// Providers cuyo estado pertenece a la sesión actual: avistamientos del
/// usuario, progreso de capítulos, estrellas de juegos y badges. Nacen
/// como singletons (sin `autoDispose`), así que su estado en memoria
/// sobrevive al logout — sin esta invalidación, al cerrar sesión y entrar
/// con otra cuenta el segundo usuario vería los datos del primero como
/// suyos (el mapa los pinta como avistamientos propios). Llamar siempre
/// tras `LocalStorage.clearSession()`, para que el nuevo ciclo de carga
/// arranque sin token viejo.
void invalidateUserScopedProviders(Ref ref) {
  ref.invalidate(sightingsProvider);
  ref.invalidate(chaptersProvider);
  ref.invalidate(gamesProgressProvider);
  ref.invalidate(badgesProvider);
}
