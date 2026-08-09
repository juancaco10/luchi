/// App-wide constants
abstract class AppConstants {
  // ── API ──────────────────────────────────────────────────────
  /// Dominio de producción por defecto. Se puede apuntar a otro entorno
  /// (staging, backend local) en tiempo de compilación:
  ///   flutter run --dart-define=API_BASE_URL=https://tu-dominio.com/api
  /// Una URL base no es un secreto — el APK la lleva dentro de todos modos —,
  /// pero nada más de la configuración del servidor debe vivir aquí.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dimgrey-dove-703529.hostingersite.com/api',
  );

  /// Cuando es true, el login/registro usa el mock local en vez de llamar a
  /// la API. **False por defecto**: el backend real ya está desplegado.
  /// Para desarrollar sin backend:
  ///   flutter run --dart-define=USE_MOCK_AUTH=true
  static const bool useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
    defaultValue: false,
  );

  /// Permite servir los datos de ejemplo (`getMockChapters`) cuando la API
  /// falla y no hay caché. **False por defecto, a propósito.**
  ///
  /// Esos mocks no son relleno inocuo: sus capítulos apuntan a vídeos de
  /// muestra de Google (BigBuckBunny.mp4). Servirlos ante cualquier fallo de
  /// red significaba enseñarle a un niño contenido que no es del curso, sin
  /// distinguirlo del real. Es preferible un error honesto con botón de
  /// reintentar.
  ///
  /// Para desarrollar sin backend:
  ///   flutter run --dart-define=ALLOW_SEED_DATA=true
  static const bool allowSeedData = bool.fromEnvironment(
    'ALLOW_SEED_DATA',
    defaultValue: false,
  );

  /// Client ID "Web" del proyecto Firebase (google-services.json,
  /// oauth_client type=3). No es secreto: un client ID de OAuth viaja en
  /// el propio cliente (APK/bundle web) por diseño; lo que hay que
  /// proteger es el lado del servidor, que valida el token contra este
  /// mismo ID en backend/api/config/database.php (GOOGLE_CLIENT_ID).
  /// Se usa como serverClientId en Android/iOS (para que el idToken sea
  /// verificable por el backend) y como clientId en web (donde no hay un
  /// google-services.json equivalente).
  static const String googleWebClientId =
      '246096129662-j68ams9ssh7d4phooq7kufpsume7db07.apps.googleusercontent.com';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Storage Keys ─────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String onboardingKey = 'onboarding_done';
  static const String chaptersBox = 'chapters_box';
  static const String sightingsBox = 'sightings_box';
  static const String badgesBox = 'badges_box';

  /// Progreso de los minijuegos (estrellas por nivel, energía, racha).
  /// Es progreso local del jugador, no caché de servidor: nunca se limpia
  /// en un refresco, solo en `clearAll()` al cerrar sesión.
  static const String gamesBox = 'games_box';

  // ── Gamification ─────────────────────────────────────────────
  static const int pointsChapter = 15;
  static const int pointsSighting = 20;

  // ── Minijuegos ───────────────────────────────────────────────
  /// Puntos por estrella ganada en un nivel de minijuego. Un nivel perfecto
  /// (3 estrellas) vale 15, igual que completar un capítulo — jugar y
  /// aprender pesan lo mismo. Solo se pagan las estrellas **nuevas**: repetir
  /// un nivel ya superado no vuelve a dar puntos (ver `recordResult` en
  /// lib/features/games/providers/games_progress_provider.dart).
  static const int pointsGameStar = 5;

  /// Energía de luz por estrella nueva. Es la moneda que se gasta en
  /// "Restaurar el Bosque", el meta-juego que une a los otros cuatro.
  ///
  /// El bosque completo cuesta 1250. Con 10 por estrella, un jugador que
  /// sacara las 120 estrellas posibles (3×10×4 juegos) se quedaba a 50 de
  /// terminar la última zona sin volver otro día — un callejón sin salida
  /// para un niño. Con 11, el juego perfecto lo cubre todo y dejar alguna
  /// estrella sin 3 estrellas se compensa jugando varios días (racha +15).
  static const int energyPerStar = 11;

  /// Bonus de energía por jugar el primer nivel del día (racha diaria).
  static const int energyDailyBonus = 15;

  /// Estrellas necesarias en un juego para desbloquear el siguiente del hub.
  static const int starsToUnlockNextGame = 8;

  /// Niveles por minijuego. El catálogo debe tener exactamente estos.
  static const int levelsPerGame = 10;

  static const Map<int, String> levelNames = {
    1: 'Observador',
    2: 'Explorador',
    3: 'Guardián',
    4: 'Maestro Guardián',
  };

  static const Map<int, int> levelThresholds = {
    1: 0,
    2: 100,
    3: 200,
    4: 400,
  };

  static int getLevelForPoints(int points) {
    if (points >= 400) return 4;
    if (points >= 200) return 3;
    if (points >= 100) return 2;
    return 1;
  }

  static String getLevelName(int points) {
    return levelNames[getLevelForPoints(points)] ?? 'Observador';
  }

  static double getLevelProgress(int points) {
    final level = getLevelForPoints(points);
    if (level >= 4) return 1.0;
    final current = levelThresholds[level]!;
    final next = levelThresholds[level + 1]!;
    return ((points - current) / (next - current)).clamp(0.0, 1.0);
  }

  // ── Animation Durations ──────────────────────────────────────
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration longAnim = Duration(milliseconds: 800);
  static const Duration rewardAnim = Duration(milliseconds: 1500);

  // ── UI ───────────────────────────────────────────────────────
  static const double borderRadius = 20.0;
  static const double cardRadius = 24.0;
  static const double buttonRadius = 16.0;
  static const double iconRadius = 12.0;
  static const double paddingHorizontal = 20.0;
  static const double paddingVertical = 16.0;

  // ── Asset Paths ──────────────────────────────────────────────
  static const String assetsImages = 'assets/images/';
  static const String assetsAnimations = 'assets/animations/';
}
