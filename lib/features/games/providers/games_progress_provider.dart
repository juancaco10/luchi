import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/game_id.dart';
import '../models/game_progress.dart';

/// Resultado de una partida, tal y como lo devuelve cualquiera de los cinco
/// juegos. Es el único contrato entre un motor de juego y la progresión.
class GameResult {
  const GameResult({
    required this.won,
    required this.stars,
    this.detail,
  });

  const GameResult.lost({this.detail})
      : won = false,
        stars = 0;

  final bool won;

  /// 0..3. Un nivel se considera superado con al menos una estrella.
  final int stars;

  /// Frase corta para el resumen ("5 de 6 llegaron a casa").
  final String? detail;
}

/// Lo que se le acredita al jugador tras `recordResult`, para poder mostrarlo
/// en la pantalla de fin de nivel sin recalcularlo allí.
class GameReward {
  const GameReward({
    required this.newStars,
    required this.points,
    required this.energy,
    required this.dailyBonus,
    required this.unlockedNextLevel,
    required this.unlockedNextGame,
  });

  /// Estrellas *nuevas* respecto a la mejor marca anterior. Si es 0, el
  /// jugador repitió un nivel sin mejorarlo y no se le paga nada.
  final int newStars;
  final int points;
  final int energy;
  final bool dailyBonus;
  final bool unlockedNextLevel;
  final GameId? unlockedNextGame;

  bool get isEmpty => points == 0 && energy == 0;
}

/// Progreso de los cinco minijuegos, persistido en la caja Hive `games_box`.
///
/// El estado se carga de forma síncrona en el constructor (Hive ya está
/// abierto desde `LocalStorage.init()`), así el hub nunca parpadea con un
/// estado vacío antes de mostrar las estrellas reales.
class GamesProgressNotifier extends StateNotifier<GamesState> {
  GamesProgressNotifier(this._ref) : super(const GamesState()) {
    _load();
  }

  final Ref _ref;

  static const _stateKey = 'state';

  void _load() {
    try {
      final raw = LocalStorage.instance.gamesBox?.get(_stateKey);
      if (raw is! Map) return;

      final progress = <GameId, GameProgress>{};
      final rawGames = raw['games'];
      if (rawGames is Map) {
        rawGames.forEach((slug, value) {
          final id = GameId.fromSlug(slug.toString());
          if (id != null && value is Map) {
            progress[id] = GameProgress.fromJson(id, value);
          }
        });
      }

      final rawZones = raw['litZones'];
      final litZones = <int>{
        if (rawZones is List)
          for (final z in rawZones)
            if (z is num) z.toInt(),
      };

      final rawDay = raw['lastPlayedDay'];

      state = GamesState(
        progress: progress,
        energy: (raw['energy'] as num?)?.toInt() ?? 0,
        litZones: litZones,
        streak: (raw['streak'] as num?)?.toInt() ?? 0,
        lastPlayedDay: rawDay is String ? DateTime.tryParse(rawDay) : null,
      );
    } catch (e, st) {
      // Un progreso corrupto o de un formato anterior no debe tumbar la app:
      // se arranca en blanco (mejor perder el progreso que no poder jugar),
      // pero se deja constancia en consola en vez de fallar en silencio.
      debugPrint(
          'GamesProgressNotifier._load falló, se arranca en blanco: $e\n$st');
    }
  }

  Future<void> _persist() async {
    final box = LocalStorage.instance.gamesBox;
    if (box == null) return;
    try {
      await box.put(_stateKey, {
        'games': {
          for (final entry in state.progress.entries)
            entry.key.slug: entry.value.toJson(),
        },
        'energy': state.energy,
        'litZones': state.litZones.toList(),
        'streak': state.streak,
        'lastPlayedDay': state.lastPlayedDay?.toIso8601String(),
      });
      // `put()` resuelve en cuanto el archivo *recibe* la escritura, no
      // cuando queda asentada en el disco físico — en Android, el sistema
      // puede matar el proceso en segundo plano (pantalla bloqueada, cambio
      // de app) antes de que ese buffer se vuelque. `flush()` fuerza el
      // volcado real a disco. Es la única caja de Hive de la app que guarda
      // progreso irrecuperable si se pierde (las demás son caché de algo
      // que se puede volver a descargar), así que aquí sí vale el costo.
      await box.flush();
    } catch (e, st) {
      // El estado en memoria (lo que ve el jugador en esta sesión) ya se
      // actualizó antes de llamar aquí; si falla el guardado en disco no
      // debe tumbar `recordResult` ni perder la actualización en curso —
      // pero antes fallaba en silencio, sin dejar ninguna pista.
      debugPrint('GamesProgressNotifier._persist falló: $e\n$st');
    }
  }

  /// Registra el final de un nivel y acredita la recompensa.
  ///
  /// Solo se pagan puntos y energía por las estrellas que **mejoran** la
  /// mejor marca previa: repetir el nivel 1 cien veces no da nada, así el
  /// progreso siempre significa avanzar y no repetir.
  Future<GameReward> recordResult(
    GameId gameId,
    int level,
    GameResult result,
  ) async {
    final previous = state.of(gameId);
    final wasUnlockedBefore = previous.highestUnlocked;
    final gainedStars =
        result.won ? (result.stars - previous.starsFor(level)).clamp(0, 3) : 0;

    final updated =
        result.won ? previous.withResult(level, result.stars) : previous;

    // ── Racha diaria ──────────────────────────────────────────
    final today = _today();
    final last = state.lastPlayedDay;
    var streak = state.streak;
    var dailyBonus = false;
    if (last == null || last.isBefore(today)) {
      dailyBonus = true;
      final yesterday = today.subtract(const Duration(days: 1));
      streak = (last != null && !last.isBefore(yesterday)) ? streak + 1 : 1;
    }

    final energyGained = gainedStars * AppConstants.energyPerStar +
        (dailyBonus ? AppConstants.energyDailyBonus : 0);
    final pointsGained = gainedStars * AppConstants.pointsGameStar;

    // Desbloqueo del siguiente juego: se comprueba antes y después para poder
    // celebrarlo una sola vez, justo en la partida que lo consigue.
    final nextGame = gameId.order + 1 < GameId.values.length
        ? GameId.values[gameId.order + 1]
        : null;
    final unlockedBefore =
        nextGame == null ? true : state.isGameUnlocked(nextGame);

    state = state.copyWith(
      progress: {...state.progress, gameId: updated},
      energy: state.energy + energyGained,
      streak: streak,
      lastPlayedDay: dailyBonus ? today : state.lastPlayedDay,
    );
    await _persist();
    _syncGameStars();

    if (pointsGained > 0) {
      // El progreso del juego (estrellas, energía) ya está guardado arriba;
      // si sumar puntos al perfil falla (p. ej. sin sesión en modo mock),
      // no debe deshacer ni bloquear lo anterior — solo se pierde el
      // contador de puntos de esa partida, no el nivel superado.
      try {
        await _ref.read(authProvider.notifier).addPoints(pointsGained);
      } catch (e, st) {
        debugPrint(
            'recordResult: addPoints falló (progreso ya guardado): $e\n$st');
      }
    }

    final unlockedNow =
        nextGame == null ? true : state.isGameUnlocked(nextGame);

    return GameReward(
      newStars: gainedStars,
      points: pointsGained,
      energy: energyGained,
      dailyBonus: dailyBonus,
      unlockedNextLevel: updated.highestUnlocked > wasUnlockedBefore,
      unlockedNextGame: (!unlockedBefore && unlockedNow) ? nextGame : null,
    );
  }

  /// Despierta una zona del bosque gastando energía. Devuelve `false` si no
  /// hay suficiente (la UI ya lo impide, pero el estado no se fía).
  Future<bool> lightZone(int zone, int cost) async {
    if (state.litZones.contains(zone) || state.energy < cost) return false;
    state = state.copyWith(
      energy: state.energy - cost,
      litZones: {...state.litZones, zone},
    );
    // El bosque restaurado también cuenta como progreso: cada zona vale una
    // estrella, así "Restaurar" aparece en el contador global igual que el
    // resto y el hub no necesita un caso especial.
    final restaurar = state.of(GameId.restaurar).withResult(zone, 1);
    state = state.copyWith(
      progress: {...state.progress, GameId.restaurar: restaurar},
    );
    await _persist();
    _syncGameStars();
    return true;
  }

  /// Informa al servidor del total absoluto de estrellas, para que
  /// `users.points`/`game_stars` y las insignias de `GET /badges`
  /// reflejen el progreso real de los juegos — hoy vive solo en este Hive
  /// local. *Fire-and-forget* a propósito: el progreso de juego es
  /// local-autoritativo (ya se guardó arriba con `_persist()` +
  /// `flush()`), así que una caída de red aquí no debe bloquear ni
  /// deshacer una partida que el niño ya terminó. Al ser un total y no un
  /// incremento, reenviarlo más tarde (la próxima vez que se llame, con
  /// conexión) corrige solo lo que faltó, sin duplicar nada — el propio
  /// backend descarta cualquier valor que no sea mayor al que ya tenía.
  void _syncGameStars() {
    // Tests and pre-bootstrap state have no authenticated session to sync.
    if (!LocalStorage.instance.isInitialized) return;
    // No `await` a propósito: se dispara y se sigue, ver comentario arriba.
    unawaited(_trySyncGameStars(state.totalStars));
  }

  Future<void> _trySyncGameStars(int stars) async {
    try {
      await _ref.read(apiClientProvider).put(
        ApiEndpoints.meGameProgress,
        data: {'stars': stars},
      );
    } catch (e) {
      debugPrint('_syncGameStars falló (progreso local ya a salvo): $e');
    }
  }

  /// Reinicia todo el progreso de juegos. Los puntos ya ganados no se quitan:
  /// son del jugador, no del juego.
  Future<void> resetAll() async {
    state = const GamesState();
    await LocalStorage.instance.gamesBox?.clear();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

final gamesProgressProvider =
    StateNotifierProvider<GamesProgressNotifier, GamesState>(
  GamesProgressNotifier.new,
);

/// Progreso de un juego concreto. Evita que cada tarjeta del hub reconstruya
/// cuando cambia el progreso de otro juego.
final gameProgressProvider = Provider.family<GameProgress, GameId>(
  (ref, id) => ref.watch(gamesProgressProvider).of(id),
);
