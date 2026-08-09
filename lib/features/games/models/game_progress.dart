import 'package:flutter/foundation.dart';

import '../../../core/utils/constants.dart';
import 'game_id.dart';

/// Estrellas obtenidas por nivel en un minijuego.
///
/// Solo se guarda la **mejor** marca de cada nivel; repetir un nivel nunca
/// baja la puntuación (ni vuelve a pagar puntos — eso lo controla
/// `GamesProgressNotifier.recordResult`).
@immutable
class GameProgress {
  const GameProgress({required this.gameId, this.stars = const {}});

  final GameId gameId;

  /// nivel (1-based) → estrellas (0..3).
  final Map<int, int> stars;

  int starsFor(int level) => stars[level] ?? 0;

  bool isCompleted(int level) => starsFor(level) > 0;

  /// Nivel más alto jugable: el siguiente al último superado. Un nivel se
  /// considera superado con al menos una estrella.
  int get highestUnlocked {
    var unlocked = 1;
    while (unlocked < AppConstants.levelsPerGame && isCompleted(unlocked)) {
      unlocked++;
    }
    return unlocked;
  }

  bool isUnlocked(int level) => level <= highestUnlocked;

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int get maxStars => AppConstants.levelsPerGame * 3;

  bool get isFinished =>
      stars.length >= AppConstants.levelsPerGame &&
      stars.values.every((s) => s > 0);

  GameProgress withResult(int level, int newStars) {
    if (newStars <= starsFor(level)) return this;
    return GameProgress(
      gameId: gameId,
      stars: {...stars, level: newStars},
    );
  }

  // ── Serialización (Hive: mapas y tipos primitivos) ────────────
  Map<String, dynamic> toJson() => {
        'stars': stars.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory GameProgress.fromJson(GameId gameId, Map raw) {
    final rawStars = raw['stars'];
    final parsed = <int, int>{};
    if (rawStars is Map) {
      rawStars.forEach((k, v) {
        final level = int.tryParse(k.toString());
        final value = (v is num) ? v.toInt() : null;
        if (level != null && value != null) parsed[level] = value.clamp(0, 3);
      });
    }
    return GameProgress(gameId: gameId, stars: parsed);
  }
}

/// Estado global de progreso de los minijuegos: estrellas por juego, energía
/// de luz acumulada, zonas del bosque restauradas y racha diaria.
@immutable
class GamesState {
  const GamesState({
    this.progress = const {},
    this.energy = 0,
    this.litZones = const {},
    this.streak = 0,
    this.lastPlayedDay,
  });

  final Map<GameId, GameProgress> progress;

  /// Energía de luz disponible para gastar en "Restaurar el Bosque".
  final int energy;

  /// Zonas ya despertadas (1-based, ver `GameCatalog.restoreZones`).
  final Set<int> litZones;

  final int streak;

  /// Día (sin hora) de la última partida, para calcular la racha.
  final DateTime? lastPlayedDay;

  GameProgress of(GameId id) =>
      progress[id] ?? GameProgress(gameId: id);

  /// Los 5 juegos están abiertos desde el principio — la progresión vive
  /// dentro de cada uno (10 niveles con desbloqueo secuencial), no entre
  /// juegos. Queda como método (en vez de borrar las llamadas) por si se
  /// quiere reactivar el desbloqueo entre juegos más adelante.
  bool isGameUnlocked(GameId id) => true;

  int get totalStars =>
      progress.values.fold(0, (sum, p) => sum + p.totalStars);

  GamesState copyWith({
    Map<GameId, GameProgress>? progress,
    int? energy,
    Set<int>? litZones,
    int? streak,
    DateTime? lastPlayedDay,
  }) {
    return GamesState(
      progress: progress ?? this.progress,
      energy: energy ?? this.energy,
      litZones: litZones ?? this.litZones,
      streak: streak ?? this.streak,
      lastPlayedDay: lastPlayedDay ?? this.lastPlayedDay,
    );
  }
}
