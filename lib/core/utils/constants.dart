/// App-wide constants
abstract class AppConstants {
  // ── API ──────────────────────────────────────────────────────
  /// Injected at build/run time, e.g.:
  ///   flutter run --dart-define=API_BASE_URL=https://tu-dominio.com/api
  /// Never hardcode a real domain here or in any committed file — this keeps
  /// the placeholder as a safe default for local development against mocks.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dimgrey-dove-703529.hostingersite.com/api',
  );

  /// When true (the default while no real backend is configured), auth uses
  /// the local mock instead of calling the API. Flip with:
  ///   flutter run --dart-define=USE_MOCK_AUTH=false
  static const bool useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
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
  static const String missionsBox = 'missions_box';
  static const String sightingsBox = 'sightings_box';

  // ── Gamification ─────────────────────────────────────────────
  static const int pointsDailyMission = 10;
  static const int pointsWeeklyMission = 30;
  static const int pointsChapter = 15;
  static const int pointsSighting = 20;

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
