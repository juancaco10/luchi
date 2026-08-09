import 'package:flutter/material.dart';

import '../models/game_id.dart';
import '../models/level_config.dart';

/// Ficha de un minijuego para el hub: identidad visual y textos.
/// El gameplay no lee nada de aquí — solo la navegación y las tarjetas.
@immutable
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.skills,
    required this.cover,
    required this.icon,
    required this.accent,
  });

  final GameId id;
  final String title;
  final String description;

  /// Qué entrena. Es lo que se le enseña al adulto que mira por encima del
  /// hombro, y da sentido educativo a la tarjeta.
  final String skills;

  final String cover;
  final IconData icon;

  /// Color de acento de la tarjeta. Es identidad del juego (como el color de
  /// un equipo), no un color de tema: por eso vive aquí y no en la paleta.
  final Color accent;
}

/// Fuente de verdad de los 5 juegos y sus 50 niveles.
///
/// La curva de dificultad se lee de un vistazo bajando por cada lista. Para
/// añadir un nivel basta con añadir una línea y subir
/// `AppConstants.levelsPerGame`; ningún motor de juego necesita cambiar.
abstract final class GameCatalog {
  static const games = <GameInfo>[
    GameInfo(
      id: GameId.explorar,
      title: 'Exploración Nocturna',
      description: 'Recorre el bosque respondiendo retos y descubre secretos.',
      skills: 'Curiosidad · Decisión',
      cover: 'assets/images/games/exploracion_nocturna_cover.jpg',
      icon: Icons.explore_rounded,
      accent: Color(0xFFFFB74D),
    ),
    GameInfo(
      id: GameId.guiar,
      title: 'Guiar Luciérnagas',
      description: 'Dibuja caminos de luz para llevarlas a salvo a su hogar.',
      skills: 'Lógica · Planificación',
      cover: 'assets/images/games/guiar_luciernagas_cover.jpg',
      icon: Icons.gesture_rounded,
      accent: Color(0xFF69F0AE),
    ),
    GameInfo(
      id: GameId.sincronizar,
      title: 'Sincronizar Luz',
      description: 'Memoriza el ritmo del bosque y repite el patrón de luz.',
      skills: 'Memoria · Atención',
      cover: 'assets/images/games/sincronizar_luz_cover.jpg',
      icon: Icons.graphic_eq_rounded,
      accent: Color(0xFFB388FF),
    ),
    GameInfo(
      id: GameId.proteger,
      title: 'Proteger la Luz',
      description: 'Cubre a las luciérnagas de la lluvia y de las sombras.',
      skills: 'Reflejos · Concentración',
      cover: 'assets/images/games/proteger_luz_cover.jpg',
      icon: Icons.shield_moon_rounded,
      accent: Color(0xFFFF8A80),
    ),
    GameInfo(
      id: GameId.restaurar,
      title: 'Restaurar el Bosque',
      description: 'Gasta tu energía de luz para despertar el bosque dormido.',
      skills: 'Conocimiento · Propósito',
      cover: 'assets/images/games/restaurar_bosque_cover.jpg',
      icon: Icons.park_rounded,
      accent: Color(0xFF40C4FF),
    ),
  ];

  static GameInfo info(GameId id) => games.firstWhere((g) => g.id == id);

  static List<LevelConfig> levels(GameId id) => switch (id) {
        GameId.explorar => quizLevels,
        GameId.guiar => guideLevels,
        GameId.sincronizar => syncLevels,
        GameId.proteger => protectLevels,
        GameId.restaurar => restoreZones,
      };

  static LevelConfig level(GameId id, int level) =>
      levels(id).firstWhere((l) => l.level == level);

  // ── 1. Exploración Nocturna ──────────────────────────────────
  // Los primeros niveles son de un solo tema y con tiempo holgado; los
  // últimos mezclan temas y aprietan el reloj.
  static const quizLevels = <QuizLevel>[
    QuizLevel(
      level: 1,
      hint: 'Empecemos por lo básico: ¿qué es una luciérnaga?',
      topics: [QuizTopic.queSon],
      questionCount: 5,
      secondsPerQuestion: 25,
    ),
    QuizLevel(
      level: 2,
      hint: 'Su luz tiene un secreto. Descúbrelo.',
      topics: [QuizTopic.bioluminiscencia],
      questionCount: 5,
      secondsPerQuestion: 25,
    ),
    QuizLevel(
      level: 3,
      hint: 'De huevo a luciérnaga: un viaje largo.',
      topics: [QuizTopic.cicloVida],
      questionCount: 6,
      secondsPerQuestion: 22,
    ),
    QuizLevel(
      level: 4,
      hint: '¿Dónde se sienten en casa?',
      topics: [QuizTopic.habitat],
      questionCount: 6,
      secondsPerQuestion: 22,
    ),
    QuizLevel(
      level: 5,
      hint: 'Repasamos lo aprendido hasta ahora.',
      topics: [QuizTopic.queSon, QuizTopic.bioluminiscencia],
      questionCount: 7,
      secondsPerQuestion: 20,
    ),
    QuizLevel(
      level: 6,
      hint: 'No todo es fácil para ellas. Conoce los peligros.',
      topics: [QuizTopic.amenazas],
      questionCount: 7,
      secondsPerQuestion: 20,
    ),
    QuizLevel(
      level: 7,
      hint: 'Ahora lo importante: cómo puedes ayudarlas.',
      topics: [QuizTopic.conservacion],
      questionCount: 7,
      secondsPerQuestion: 18,
    ),
    QuizLevel(
      level: 8,
      hint: 'Su casa y sus peligros, todo junto.',
      topics: [QuizTopic.habitat, QuizTopic.amenazas],
      questionCount: 8,
      secondsPerQuestion: 18,
    ),
    QuizLevel(
      level: 9,
      hint: 'Casi guardián. Demuestra lo que sabes.',
      topics: [
        QuizTopic.cicloVida,
        QuizTopic.amenazas,
        QuizTopic.conservacion,
      ],
      questionCount: 9,
      secondsPerQuestion: 16,
    ),
    QuizLevel(
      level: 10,
      hint: 'La prueba final del Guardián del Bosque.',
      topics: QuizTopic.values,
      questionCount: 10,
      secondsPerQuestion: 15,
    ),
  ];

  // ── 2. Guiar Luciérnagas ─────────────────────────────────────
  // Curva: 2→8 luciérnagas, de una roca suelta a agua en movimiento y
  // sombras, con la energía cada vez más justa respecto al recorrido.
  static const guideLevels = <GuideLevel>[
    GuideLevel(
      level: 1,
      hint: 'Desliza el dedo para dibujar un camino de luz hasta el árbol.',
      fireflies: 2,
      required_: 1,
      energy: 2400,
      obstacles: [
        ObstacleSpec(x: 0.5, y: 0.5, radius: 0.09),
      ],
    ),
    GuideLevel(
      level: 2,
      hint: 'Dos rocas en el camino. Rodéalas con calma.',
      fireflies: 3,
      required_: 2,
      energy: 2300,
      obstacles: [
        ObstacleSpec(x: 0.32, y: 0.55, radius: 0.09),
        ObstacleSpec(x: 0.70, y: 0.38, radius: 0.09),
      ],
    ),
    GuideLevel(
      level: 3,
      hint: 'El agua apaga su luz. No las lleves al charco.',
      fireflies: 3,
      required_: 2,
      energy: 2200,
      obstacles: [
        ObstacleSpec(x: 0.5, y: 0.60, radius: 0.14, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.20, y: 0.35, radius: 0.08),
      ],
    ),
    GuideLevel(
      level: 4,
      hint: 'Un pasillo estrecho. Dibuja despacio.',
      fireflies: 4,
      required_: 3,
      energy: 2100,
      obstacles: [
        ObstacleSpec(x: 0.18, y: 0.52, radius: 0.13),
        ObstacleSpec(x: 0.82, y: 0.52, radius: 0.13),
        ObstacleSpec(x: 0.5, y: 0.28, radius: 0.08),
      ],
    ),
    GuideLevel(
      level: 5,
      hint: 'En la sombra gastas más luz. Cruza rápido.',
      fireflies: 4,
      required_: 3,
      energy: 2000,
      obstacles: [
        ObstacleSpec(x: 0.5, y: 0.45, radius: 0.18, kind: ObstacleKind.sombra),
        ObstacleSpec(x: 0.25, y: 0.68, radius: 0.09),
        ObstacleSpec(x: 0.75, y: 0.68, radius: 0.09),
      ],
    ),
    GuideLevel(
      level: 6,
      hint: 'Cuidado: esta roca se mueve.',
      fireflies: 5,
      required_: 3,
      energy: 1950,
      obstacles: [
        ObstacleSpec(
          x: 0.5,
          y: 0.55,
          radius: 0.10,
          driftX: 0.18,
          driftRange: 0.28,
        ),
        ObstacleSpec(x: 0.5, y: 0.30, radius: 0.09, kind: ObstacleKind.agua),
      ],
    ),
    GuideLevel(
      level: 7,
      hint: 'Un río cruza el bosque. Busca el paso.',
      fireflies: 5,
      required_: 4,
      energy: 1900,
      obstacles: [
        ObstacleSpec(x: 0.16, y: 0.58, radius: 0.13, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.44, y: 0.58, radius: 0.13, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.86, y: 0.58, radius: 0.13, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.5, y: 0.32, radius: 0.09),
      ],
    ),
    GuideLevel(
      level: 8,
      hint: 'Dos sombras y poco margen. Piensa el camino antes de dibujar.',
      fireflies: 6,
      required_: 4,
      energy: 1800,
      obstacles: [
        ObstacleSpec(x: 0.28, y: 0.62, radius: 0.15, kind: ObstacleKind.sombra),
        ObstacleSpec(x: 0.74, y: 0.40, radius: 0.15, kind: ObstacleKind.sombra),
        ObstacleSpec(
          x: 0.5,
          y: 0.50,
          radius: 0.08,
          driftX: 0.22,
          driftRange: 0.30,
        ),
      ],
    ),
    GuideLevel(
      level: 9,
      hint: 'Todo el bosque a la vez. Tú puedes.',
      fireflies: 7,
      required_: 5,
      energy: 1750,
      obstacles: [
        ObstacleSpec(x: 0.22, y: 0.70, radius: 0.11, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.78, y: 0.70, radius: 0.11, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.5, y: 0.48, radius: 0.14, kind: ObstacleKind.sombra),
        ObstacleSpec(
          x: 0.35,
          y: 0.30,
          radius: 0.08,
          driftX: 0.24,
          driftRange: 0.26,
        ),
      ],
    ),
    GuideLevel(
      level: 10,
      hint: 'La última noche. Llévalas a todas a casa.',
      fireflies: 8,
      required_: 6,
      energy: 1700,
      obstacles: [
        ObstacleSpec(x: 0.16, y: 0.72, radius: 0.12, kind: ObstacleKind.agua),
        ObstacleSpec(x: 0.50, y: 0.72, radius: 0.10, kind: ObstacleKind.sombra),
        ObstacleSpec(x: 0.84, y: 0.72, radius: 0.12, kind: ObstacleKind.agua),
        ObstacleSpec(
          x: 0.30,
          y: 0.50,
          radius: 0.09,
          driftX: 0.26,
          driftRange: 0.30,
        ),
        ObstacleSpec(
          x: 0.70,
          y: 0.34,
          radius: 0.09,
          driftX: -0.26,
          driftRange: 0.30,
        ),
      ],
    ),
  ];

  // ── 3. Sincronizar Luz ───────────────────────────────────────
  // Crece en tres ejes a la vez: más luciérnagas, secuencias más largas y
  // destellos más rápidos.
  static const syncLevels = <SyncLevel>[
    SyncLevel(
      level: 1,
      hint: 'Mira qué luciérnagas se encienden y tócalas en el mismo orden.',
      nodes: 3,
      startLength: 2,
      rounds: 3,
      showMs: 600,
      gapMs: 320,
    ),
    SyncLevel(
      level: 2,
      hint: 'Ahora son cuatro. Fíjate bien.',
      nodes: 4,
      startLength: 2,
      rounds: 4,
      showMs: 560,
      gapMs: 300,
    ),
    SyncLevel(
      level: 3,
      hint: 'La secuencia empieza más larga.',
      nodes: 4,
      startLength: 3,
      rounds: 4,
      showMs: 520,
      gapMs: 280,
    ),
    SyncLevel(
      level: 4,
      hint: 'Cinco luciérnagas parpadeando.',
      nodes: 5,
      startLength: 3,
      rounds: 4,
      showMs: 480,
      gapMs: 260,
    ),
    SyncLevel(
      level: 5,
      hint: 'El bosque se acelera.',
      nodes: 5,
      startLength: 3,
      rounds: 5,
      showMs: 440,
      gapMs: 240,
    ),
    SyncLevel(
      level: 6,
      hint: 'Seis luces. Respira y concéntrate.',
      nodes: 6,
      startLength: 4,
      rounds: 5,
      showMs: 400,
      gapMs: 220,
    ),
    SyncLevel(
      level: 7,
      hint: 'Más rápido todavía.',
      nodes: 6,
      startLength: 4,
      rounds: 6,
      showMs: 360,
      gapMs: 200,
    ),
    SyncLevel(
      level: 8,
      hint: 'Siete luciérnagas cantan a la vez.',
      nodes: 7,
      startLength: 4,
      rounds: 6,
      showMs: 330,
      gapMs: 190,
    ),
    SyncLevel(
      level: 9,
      hint: 'Secuencias largas desde el principio.',
      nodes: 7,
      startLength: 5,
      rounds: 6,
      showMs: 300,
      gapMs: 175,
    ),
    SyncLevel(
      level: 10,
      hint: 'El gran concierto del bosque. Ocho luces.',
      nodes: 8,
      startLength: 5,
      rounds: 7,
      showMs: 280,
      gapMs: 160,
    ),
  ];

  // ── 4. Proteger la Luz ───────────────────────────────────────
  // Los tipos de amenaza se introducen de uno en uno para que cada nivel
  // enseñe algo antes de combinarlo.
  static const protectLevels = <ProtectLevel>[
    ProtectLevel(
      level: 1,
      hint: 'Arrastra el escudo de luz para tapar la lluvia.',
      durationSeconds: 25,
      threats: [ThreatKind.gota],
      spawnStart: 1.6,
      spawnEnd: 1.2,
      fallSpeed: 0.28,
    ),
    ProtectLevel(
      level: 2,
      hint: 'Llueve más fuerte.',
      durationSeconds: 30,
      threats: [ThreatKind.gota],
      spawnStart: 1.4,
      spawnEnd: 0.95,
      fallSpeed: 0.32,
    ),
    ProtectLevel(
      level: 3,
      hint: 'Aparecen las sombras. Se disipan al tocar tu luz.',
      durationSeconds: 30,
      threats: [ThreatKind.gota, ThreatKind.sombra],
      spawnStart: 1.3,
      spawnEnd: 0.9,
      fallSpeed: 0.34,
    ),
    ProtectLevel(
      level: 4,
      hint: 'Las sombras hacen zigzag. Anticípate.',
      durationSeconds: 35,
      threats: [ThreatKind.sombra],
      spawnStart: 1.2,
      spawnEnd: 0.85,
      fallSpeed: 0.36,
    ),
    ProtectLevel(
      level: 5,
      hint: 'Llegan las nubes: grandes y pesadas.',
      durationSeconds: 35,
      threats: [ThreatKind.gota, ThreatKind.nube],
      spawnStart: 1.2,
      spawnEnd: 0.8,
      fallSpeed: 0.34,
    ),
    ProtectLevel(
      level: 6,
      hint: 'Las tres amenazas juntas.',
      durationSeconds: 40,
      threats: [ThreatKind.gota, ThreatKind.sombra, ThreatKind.nube],
      spawnStart: 1.1,
      spawnEnd: 0.75,
      fallSpeed: 0.38,
    ),
    ProtectLevel(
      level: 7,
      hint: 'Tormenta cerrada.',
      durationSeconds: 40,
      threats: [ThreatKind.gota, ThreatKind.sombra, ThreatKind.nube],
      spawnStart: 1.0,
      spawnEnd: 0.62,
      fallSpeed: 0.42,
    ),
    ProtectLevel(
      level: 8,
      hint: 'Caen más rápido. No sueltes el escudo.',
      durationSeconds: 45,
      threats: [ThreatKind.gota, ThreatKind.sombra, ThreatKind.nube],
      spawnStart: 0.9,
      spawnEnd: 0.55,
      fallSpeed: 0.46,
    ),
    ProtectLevel(
      level: 9,
      hint: 'Cuatro luciérnagas que cuidar.',
      durationSeconds: 45,
      threats: [ThreatKind.gota, ThreatKind.sombra, ThreatKind.nube],
      spawnStart: 0.85,
      spawnEnd: 0.5,
      fallSpeed: 0.5,
      fireflies: 4,
    ),
    ProtectLevel(
      level: 10,
      hint: 'La noche más larga del bosque. Protégelas a todas.',
      durationSeconds: 50,
      threats: [ThreatKind.gota, ThreatKind.sombra, ThreatKind.nube],
      spawnStart: 0.75,
      spawnEnd: 0.42,
      fallSpeed: 0.55,
      fireflies: 4,
    ),
  ];

  // ── 5. Restaurar el Bosque ───────────────────────────────────
  // No son "niveles" que se juegan, sino zonas que se compran con la energía
  // ganada en los otros cuatro juegos. El coste sube para que restaurar el
  // bosque entero requiera dominar los demás.
  static const restoreZones = <RestoreZone>[
    RestoreZone(
      level: 1,
      hint: 'Todo empieza por un claro.',
      name: 'El Claro',
      energyCost: 20,
      x: 0.50,
      y: 0.82,
    ),
    RestoreZone(
      level: 2,
      hint: 'Sin agua limpia no hay luciérnagas.',
      name: 'El Arroyo',
      energyCost: 35,
      x: 0.24,
      y: 0.74,
    ),
    RestoreZone(
      level: 3,
      hint: 'Los helechos guardan la humedad.',
      name: 'Los Helechos',
      energyCost: 50,
      x: 0.76,
      y: 0.70,
    ),
    RestoreZone(
      level: 4,
      hint: 'Aquí ponen sus huevos.',
      name: 'El Musgo',
      energyCost: 70,
      x: 0.36,
      y: 0.60,
    ),
    RestoreZone(
      level: 5,
      hint: 'El roble más viejo del bosque.',
      name: 'El Roble Anciano',
      energyCost: 95,
      x: 0.66,
      y: 0.53,
    ),
    RestoreZone(
      level: 6,
      hint: 'Las flores llaman a los insectos.',
      name: 'El Prado',
      energyCost: 120,
      x: 0.22,
      y: 0.46,
    ),
    RestoreZone(
      level: 7,
      hint: 'Un refugio para las larvas.',
      name: 'La Hojarasca',
      energyCost: 150,
      x: 0.78,
      y: 0.38,
    ),
    RestoreZone(
      level: 8,
      hint: 'Menos luz artificial, más estrellas.',
      name: 'El Cielo Oscuro',
      energyCost: 185,
      x: 0.40,
      y: 0.30,
    ),
    RestoreZone(
      level: 9,
      hint: 'El corazón húmedo del bosque.',
      name: 'La Laguna',
      energyCost: 225,
      x: 0.68,
      y: 0.22,
    ),
    RestoreZone(
      level: 10,
      hint: 'Cuando todo brilla, vuelven a casa.',
      name: 'El Bosque Entero',
      energyCost: 300,
      x: 0.50,
      y: 0.12,
    ),
  ];
}
