/// API endpoint paths
abstract class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────
  static const String register = '/register';
  static const String login = '/login';
  static const String googleLogin = '/auth/google';
  static const String guestLogin = '/auth/guest';
  static const String me = '/me';

  // ── Education ────────────────────────────────────────────────
  static const String chapters = '/chapters';
  static const String completeChapter = '/complete-chapter';

  // ── Missions ─────────────────────────────────────────────────
  static const String missions = '/missions';
  static const String completeMission = '/complete-mission';

  // ── Sightings ────────────────────────────────────────────────
  static const String sightings = '/sightings';
  static const String mySightings = '/my-sightings';

  // ── Profile ──────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String badges = '/badges';
}
