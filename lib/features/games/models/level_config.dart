import 'package:flutter/foundation.dart';

/// Configuración de un nivel. Cada minijuego tiene su subclase con los
/// parámetros que su motor entiende; el motor **nunca** hardcodea dificultad,
/// solo lee de aquí. Añadir un nivel = añadir una línea en
/// `data/game_catalog.dart`, sin tocar la lógica de juego.
@immutable
sealed class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.hint,
  });

  /// 1-based. Es el número que ve el niño y el que viaja en la ruta.
  final int level;

  /// Frase corta que se muestra antes de empezar. Lenguaje de 6–12 años:
  /// una instrucción, no un tutorial.
  final String hint;
}

// ── 1. Exploración Nocturna (quiz) ─────────────────────────────

/// Temas del banco de preguntas. Cada nivel del quiz sortea preguntas de uno
/// o varios temas, así la progresión enseña algo nuevo en vez de repetir.
enum QuizTopic {
  queSon('¿Qué son?'),
  bioluminiscencia('Su luz'),
  cicloVida('Cómo crecen'),
  habitat('Dónde viven'),
  amenazas('Peligros'),
  conservacion('Cómo ayudar');

  const QuizTopic(this.label);
  final String label;
}

@immutable
final class QuizLevel extends LevelConfig {
  const QuizLevel({
    required super.level,
    required super.hint,
    required this.topics,
    required this.questionCount,
    required this.secondsPerQuestion,
  });

  final List<QuizTopic> topics;
  final int questionCount;
  final int secondsPerQuestion;
}

// ── 2. Guiar Luciérnagas ───────────────────────────────────────

/// Un obstáculo del mapa, en **coordenadas normalizadas** (0..1 sobre el
/// ancho/alto de la pantalla). Así el mismo nivel se ve igual en un móvil
/// pequeño y en una tablet sin recalcular nada.
@immutable
class ObstacleSpec {
  const ObstacleSpec({
    required this.x,
    required this.y,
    required this.radius,
    this.kind = ObstacleKind.roca,
    this.driftX = 0,
    this.driftRange = 0,
  });

  final double x;
  final double y;

  /// Radio normalizado sobre el **ancho** de la pantalla.
  final double radius;
  final ObstacleKind kind;

  /// Velocidad horizontal en anchos de pantalla por segundo. 0 = estático.
  final double driftX;

  /// Amplitud del vaivén, también normalizada. Solo aplica si `driftX != 0`.
  final double driftRange;
}

enum ObstacleKind {
  /// Bloquea: la luciérnaga rebota y pierde un poco de rumbo.
  roca,

  /// Apaga la luz: la luciérnaga se atenúa y hay que volver a guiarla.
  agua,

  /// Zona oscura: ralentiza y consume energía extra mientras se esté dentro.
  sombra,
}

@immutable
final class GuideLevel extends LevelConfig {
  const GuideLevel({
    required super.level,
    required super.hint,
    required this.fireflies,
    required this.required_,
    required this.energy,
    required this.obstacles,
    this.homeX = 0.5,
    this.homeY = 0.14,
    this.startY = 0.86,
  });

  /// Cuántas luciérnagas aparecen.
  final int fireflies;

  /// Cuántas hay que llevar a casa para ganar. Siempre `<= fireflies`.
  final int required_;

  /// Energía de luz disponible para dibujar. Es el único recurso del juego:
  /// no hay temporizador, así un niño puede pensar sin agobiarse.
  final double energy;

  final List<ObstacleSpec> obstacles;
  final double homeX;
  final double homeY;
  final double startY;
}

// ── 3. Sincronizar Luz ─────────────────────────────────────────

@immutable
final class SyncLevel extends LevelConfig {
  const SyncLevel({
    required super.level,
    required super.hint,
    required this.nodes,
    required this.startLength,
    required this.rounds,
    required this.showMs,
    required this.gapMs,
  });

  /// Cuántas luciérnagas hay en pantalla (3..8).
  final int nodes;

  /// Longitud de la secuencia en la primera ronda; crece +1 por ronda.
  final int startLength;

  /// Rondas para completar el nivel.
  final int rounds;

  /// Milisegundos que cada luciérnaga se queda encendida al mostrar.
  final int showMs;

  /// Milisegundos de pausa entre destellos.
  final int gapMs;
}

// ── 4. Proteger la Luz ─────────────────────────────────────────

enum ThreatKind {
  /// Cae recto y rebota en el escudo.
  gota,

  /// Zigzaguea y se disipa al tocar el escudo.
  sombra,

  /// Lenta y grande, empuja al escudo hacia abajo mientras la contiene.
  nube,
}

@immutable
final class ProtectLevel extends LevelConfig {
  const ProtectLevel({
    required super.level,
    required super.hint,
    required this.durationSeconds,
    required this.threats,
    required this.spawnStart,
    required this.spawnEnd,
    required this.fallSpeed,
    this.fireflies = 3,
  });

  /// Cuánto hay que aguantar. Sesiones cortas a propósito.
  final double durationSeconds;

  final List<ThreatKind> threats;

  /// Segundos entre apariciones al empezar y al terminar el nivel; se
  /// interpola linealmente, así la tensión sube sola.
  final double spawnStart;
  final double spawnEnd;

  /// Velocidad de caída en altos de pantalla por segundo.
  final double fallSpeed;

  /// Luciérnagas a proteger = vidas.
  final int fireflies;
}

// ── 5. Restaurar el Bosque ─────────────────────────────────────

@immutable
final class RestoreZone extends LevelConfig {
  const RestoreZone({
    required super.level,
    required super.hint,
    required this.name,
    required this.energyCost,
    required this.x,
    required this.y,
  });

  final String name;

  /// Energía de luz necesaria para despertar la zona.
  final int energyCost;

  /// Posición normalizada en el mapa del bosque.
  final double x;
  final double y;
}
