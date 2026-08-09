import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Singleton for local storage — tokens, cached data, offline queue
class LocalStorage {
  static LocalStorage? _instance;
  late SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;
  final _secureStorage = const FlutterSecureStorage();

  // The auth token needs synchronous access in a few hot paths (GoRouter's
  // `redirect`, the Dio auth interceptor), so we mirror it in memory once
  // loaded from secure storage at init(). Secure storage remains the source
  // of truth; this is purely a read cache.
  String? _cachedToken;

  LocalStorage._();
  static LocalStorage get instance => _instance ??= LocalStorage._();

  Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();

    // Open untyped Hive boxes for offline caching
    await Hive.openBox(AppConstants.chaptersBox);
    await Hive.openBox(AppConstants.sightingsBox);
    await Hive.openBox(AppConstants.gamesBox);
    await Hive.openBox(AppConstants.badgesBox);

    // One-time migration: earlier builds stored the token in plaintext
    // SharedPreferences. Move it to secure storage and remove the old copy.
    final legacyToken = _prefs.getString(AppConstants.tokenKey);
    if (legacyToken != null) {
      await _secureStorage.write(key: AppConstants.tokenKey, value: legacyToken);
      await _prefs.remove(AppConstants.tokenKey);
    }
    _cachedToken = await _secureStorage.read(key: AppConstants.tokenKey);
  }

  /// Test seam: wires only SharedPreferences, skipping Hive/path_provider and
  /// secure storage so widget tests can exercise screens that read prefs.
  @visibleForTesting
  Future<void> initForTesting() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Auth Token (flutter_secure_storage — Keychain/Keystore) ───
  String? getToken() => _cachedToken;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  bool get isLoggedIn => getToken() != null;

  // ── Onboarding ───────────────────────────────────────────────
  bool get onboardingDone => _prefs.getBool(AppConstants.onboardingKey) ?? false;

  /// La primera vez que se inicia un juego se marca aquí: el cartel de
  /// instrucciones solo se muestra en esa primera apertura, no en cada nivel.
  bool isFirstGameStart(String gameKey) {
    final key = 'first_game_start_$gameKey';
    final first = !(_prefs.getBool(key) ?? false);
    if (first) {
      _prefs.setBool(key, true);
    }
    return first;
  }

  Future<void> setOnboardingDone() =>
      _prefs.setBool(AppConstants.onboardingKey, true);

  // ── User Cache ───────────────────────────────────────────────
  Map<String, dynamic>? getUser() {
    final raw = _prefs.getString(AppConstants.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(AppConstants.userKey, jsonEncode(user));

  Future<void> clearUser() => _prefs.remove(AppConstants.userKey);

  // ── Hive Boxes (untyped) ──────────────────────────────────────
  Box get chaptersBox => Hive.box(AppConstants.chaptersBox);
  Box get sightingsBox => Hive.box(AppConstants.sightingsBox);
  Box get gamesBox => Hive.box(AppConstants.gamesBox);
  Box get badgesBox => Hive.box(AppConstants.badgesBox);

  // ── Cache Chapters ───────────────────────────────────────────
  Future<void> cacheChapters(List<Map<String, dynamic>> chapters) async {
    await chaptersBox.clear();
    for (var ch in chapters) {
      await chaptersBox.put(ch['id'].toString(), ch);
    }
  }

  List<Map<String, dynamic>> getCachedChapters() {
    return chaptersBox.values
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Cache Badges ─────────────────────────────────────────────
  Future<void> cacheBadges(List<Map<String, dynamic>> badges) async {
    await badgesBox.clear();
    for (var b in badges) {
      await badgesBox.put(b['id'].toString(), b);
    }
  }

  List<Map<String, dynamic>> getCachedBadges() {
    return badgesBox.values
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Offline Sighting Queue ───────────────────────────────────
  // `Box.add()` uses Hive's own auto-incrementing integer keys, so two
  // sightings queued in the same millisecond can't collide and silently
  // overwrite each other the way a `DateTime.now()`-derived string key did.
  Future<void> queueSighting(Map<String, dynamic> sighting) async {
    await sightingsBox.add(sighting);
  }

  /// Keyed view of the queue, so a failed sync can delete just the entries
  /// that succeeded instead of clearing the whole box and re-inserting the
  /// ones that failed — that clear-then-reinsert had a window where an app
  /// kill between the two steps lost every pending sighting.
  Map<dynamic, Map<String, dynamic>> getPendingSightingsWithKeys() {
    return sightingsBox.toMap().map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
        );
  }

  List<Map<String, dynamic>> getPendingSightings() =>
      getPendingSightingsWithKeys().values.toList();

  Future<void> removePendingSighting(dynamic key) => sightingsBox.delete(key);

  Future<void> clearPendingSightings() => sightingsBox.clear();

  // ── Full Clear ───────────────────────────────────────────────
  Future<void> clearAll() async {
    await clearUser();
    await clearToken();
    await chaptersBox.clear();
    await sightingsBox.clear();
    await gamesBox.clear();
  }
}
