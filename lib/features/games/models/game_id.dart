/// Los cinco minijuegos de "Guardianes del Bosque".
///
/// El `slug` es lo que viaja en la ruta (`/game/guiar/play/3`) y lo que se
/// usa como clave en Hive, así que **no se puede renombrar** sin migrar el
/// progreso guardado de los jugadores. El nombre visible sí puede cambiar:
/// vive en el catálogo (`data/game_catalog.dart`), no aquí.
enum GameId {
  explorar('explorar'),
  guiar('guiar'),
  sincronizar('sincronizar'),
  proteger('proteger'),
  restaurar('restaurar');

  const GameId(this.slug);

  final String slug;

  /// Orden de desbloqueo en el hub. Coincide con el orden de declaración.
  int get order => index;

  static GameId? fromSlug(String? slug) {
    if (slug == null) return null;
    for (final id in GameId.values) {
      if (id.slug == slug) return id;
    }
    return null;
  }
}
