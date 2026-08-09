/// API endpoint paths
abstract class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────
  static const String register = '/register';
  static const String login = '/login';
  static const String googleLogin = '/auth/google';
  static const String guestLogin = '/auth/guest';
  static const String me = '/me';
  static const String meGameProgress = '/me/game-progress';

  // ── Education ────────────────────────────────────────────────
  static const String chapters = '/chapters';
  static const String completeChapter = '/complete-chapter';

  // ── Sightings ────────────────────────────────────────────────
  static const String sightings = '/sightings';
  static const String mySightings = '/my-sightings';
  static String sighting(int id) => '/sightings/$id';
  static String archiveSighting(int id) => '/sightings/$id/archive';
  static String likeSighting(int id) => '/sightings/$id/like';
  static const String uploadSightingPhoto = '/uploads/sighting-photo';

  // ── Moderation (backend/admin/moderation.php is the primary UI;
  //    this endpoint exists for completeness/future tooling) ──────
  static const String moderationQueue = '/moderation/queue';
  static String moderateSighting(int id) => '/sightings/$id/moderate';

  // ── Profile ──────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String badges = '/badges';
}
