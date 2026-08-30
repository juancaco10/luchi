import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Singleton for local storage — tokens, cached data, offline queue.
///
/// ── Namespacing por cuenta ──────────────────────────────────────────
/// Varias cuentas Google pueden convivir en el mismo dispositivo. Para que
/// no se mezclen sus datos, cada caja Hive (capítulos, avistamientos
/// propios/offline, juegos, badges, feed) se abre con un sufijo `_u<id>`
/// atado a `_activeUserId`. `openUserBoxes(id)` se llama tras cada login;
/// `clearSession()` (logout) cierra esas cajas pero NO borra su contenido
/// en disco — así, si el mismo usuario vuelve a entrar, su caché sigue
/// ahí y la app pinta al instante. `purgeUserData(id)` sí borra el
/// contenido, y es lo que usa `deleteAccount()`.
class LocalStorage {
  static LocalStorage? _instance;
  late SharedPreferences _prefs;
  bool _initialized = false;
  SharedPreferences get prefs => _prefs;
  bool get isInitialized => _initialized;
  final _secureStorage = const FlutterSecureStorage();

  // The auth token needs synchronous access in a few hot paths (GoRouter's
  // `redirect`, the Dio auth interceptor), so we mirror it in memory once
  // loaded from secure storage at init(). Secure storage remains the source
  // of truth; this is purely a read cache.
  String? _cachedToken;

  /// `user_id` de la cuenta activa, o `null` si no hay sesión / aún no se
  /// han abierto sus cajas. Determina el sufijo de todas las cajas Hive.
  String? _activeUserId;

  LocalStorage._();
  static LocalStorage get instance => _instance ??= LocalStorage._();

  Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    // flutter_secure_storage está respaldado por AndroidKeystore, y en
    // algunos dispositivos (Samsung/Knox observado en producción) el
    // acceso al keystore puede colgarse indefinidamente en el primer
    // arranque tras instalar/actualizar la app — sin timeout, eso deja
    // main() esperando para siempre antes de runApp(): pantalla de splash
    // nativa congelada sin ningún frame de Flutter, sin crash ni log.
    // Con timeout, en el peor caso el usuario simplemente vuelve a
    // aparecer como no-logueado (puede volver a iniciar sesión) en vez de
    // que la app quede inutilizable.
    const secureStorageTimeout = Duration(seconds: 5);
    try {
      // One-time migration: earlier builds stored the token in plaintext
      // SharedPreferences. Move it to secure storage and remove the old copy.
      final legacyToken = _prefs.getString(AppConstants.tokenKey);
      if (legacyToken != null) {
        await _secureStorage
            .write(key: AppConstants.tokenKey, value: legacyToken)
            .timeout(secureStorageTimeout);
        await _prefs.remove(AppConstants.tokenKey);
      }
      _cachedToken = await _secureStorage
          .read(key: AppConstants.tokenKey)
          .timeout(secureStorageTimeout);
    } catch (_) {
      _cachedToken = null;
    }

    // Si había una sesión abierta cuando la app se cerró, reabrir sus
    // cajas ya mismo — si no, cualquier lectura de caché antes del primer
    // login de este proceso (p. ej. hidratar el feed en el constructor del
    // provider) fallaría por caja no abierta ("Box not found").
    //
    // El puntero preferido es `activeUserIdKey`, pero una instalación que
    // ya tenía sesión iniciada ANTES de este namespacing nunca lo guardó:
    // para esa, se cae al `id` del usuario cacheado en `current_user` —
    // así una cuenta ya logueada se namespacea en su primer arranque tras
    // la actualización, en vez de quedarse para siempre en las cajas
    // legacy sin sufijo (que rompería el aislamiento multicuenta).
    final savedUserId = _prefs.getString(AppConstants.activeUserIdKey) ??
        getUser()?['id']?.toString();
    if (savedUserId != null && _cachedToken != null) {
      await openUserBoxes(savedUserId);
    } else {
      // Sin sesión: no hay `user_id` con el que namespacear. Se abren las
      // cajas base (sin sufijo) para que cualquier lectura anterior al
      // primer login de este proceso no reviente — mismo comportamiento
      // que antes del namespacing. `openUserBoxes` las migrará a las
      // namespaced en cuanto haya login.
      await _ensureAnonBoxesOpen();
    }
  }

  Future<void> _ensureAnonBoxesOpen() async {
    for (final base in _boxNames) {
      if (!Hive.isBoxOpen(base)) {
        await Hive.openBox(base);
      }
    }
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
    try {
      await _secureStorage
          .write(key: AppConstants.tokenKey, value: token)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // La sesión sigue funcionando en memoria (_cachedToken ya está
      // puesto); en el peor caso, se pierde al reiniciar la app.
    }
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    try {
      await _secureStorage
          .delete(key: AppConstants.tokenKey)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ya se limpió en memoria; el peor caso es un token viejo huérfano
      // en el keystore que ya no se usa para nada.
    }
  }

  bool get isLoggedIn => getToken() != null;

  // ── Cuenta activa / cajas por usuario ───────────────────────────
  String? get activeUserId => _activeUserId;

  static const _boxNames = [
    AppConstants.chaptersBox,
    AppConstants.sightingsBox,
    AppConstants.gamesBox,
    AppConstants.badgesBox,
    AppConstants.feedBox,
  ];

  // Sin usuario activo (tests, o un futuro caller antes del primer login)
  // se usa el nombre base sin sufijo — así el comportamiento para quien no
  // pasa por `openUserBoxes` es exactamente el de antes del namespacing.
  String _boxNameFor(String base) =>
      _activeUserId == null ? base : '${base}_u$_activeUserId';

  /// Abre (o reabre) las cajas Hive del usuario `userId` y las deja como
  /// activas. Llamar tras cada login/registro/Google/invitado, y en
  /// `init()` si ya había sesión guardada.
  ///
  /// Migración de un solo uso: si existen las cajas legacy sin sufijo con
  /// datos (versiones previas al namespacing) y las del usuario aún no
  /// existen, se copia su contenido una vez — para no perder, por ejemplo,
  /// una cola offline pendiente de antes de esta actualización.
  Future<void> openUserBoxes(String userId) async {
    _activeUserId = userId;
    await _prefs.setString(AppConstants.activeUserIdKey, userId);

    for (final base in _boxNames) {
      final namespaced = _boxNameFor(base);
      if (!Hive.isBoxOpen(namespaced)) {
        await Hive.openBox(namespaced);
      }

      // Migración legacy → namespaced (solo si la nueva caja está vacía).
      if (base != AppConstants.feedBox &&
          Hive.box(namespaced).isEmpty &&
          await Hive.boxExists(base)) {
        final legacy =
            Hive.isBoxOpen(base) ? Hive.box(base) : await Hive.openBox(base);
        if (legacy.isNotEmpty) {
          final target = Hive.box(namespaced);
          for (final key in legacy.keys) {
            await target.put(key, legacy.get(key));
          }
        }
        await legacy.clear();
        await legacy.close();
      }
    }
  }

  /// Cierra (sin borrar) las cajas del usuario activo. Sus datos siguen en
  /// disco para la próxima vez que inicie sesión esa misma cuenta.
  Future<void> closeUserBoxes() async {
    for (final base in _boxNames) {
      final name = _boxNameFor(base);
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
    }
    _activeUserId = null;
  }

  // ── Onboarding ───────────────────────────────────────────────
  // Global al dispositivo, no por cuenta: es una pantalla de bienvenida de
  // la app, no algo que dependa de quién inició sesión.
  bool get onboardingDone =>
      _prefs.getBool(AppConstants.onboardingKey) ?? false;
  bool get parentalConsentDone =>
      _prefs.getBool(AppConstants.parentalConsentKey) ?? false;
  String? get parentalConsentAt =>
      _prefs.getString(AppConstants.parentalConsentAtKey);
  String? get parentalConsentPolicyVersion =>
      _prefs.getString(AppConstants.parentalConsentPolicyKey);

  /// La primera vez que se inicia un juego se marca aquí: el cartel de
  /// instrucciones solo se muestra en esa primera apertura, no en cada
  /// nivel. Namespaced por usuario — si no, la cuenta B heredaría el "ya
  /// visto" de la cuenta A en el mismo dispositivo.
  bool isFirstGameStart(String gameKey) {
    final key = _activeUserId == null
        ? 'first_game_start_$gameKey'
        : 'first_game_start_${_activeUserId}_$gameKey';
    final first = !(_prefs.getBool(key) ?? false);
    if (first) {
      _prefs.setBool(key, true);
    }
    return first;
  }

  Future<void> setOnboardingDone() =>
      _prefs.setBool(AppConstants.onboardingKey, true);

  Future<void> recordParentalConsent() async {
    await _prefs.setBool(AppConstants.parentalConsentKey, true);
    await _prefs.setString(
      AppConstants.parentalConsentAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await _prefs.setString(
      AppConstants.parentalConsentPolicyKey,
      AppConstants.parentalConsentPolicyVersion,
    );
  }

  // ── User Cache ───────────────────────────────────────────────
  Map<String, dynamic>? getUser() {
    final raw = _prefs.getString(AppConstants.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(AppConstants.userKey, jsonEncode(user));

  Future<void> clearUser() => _prefs.remove(AppConstants.userKey);

  // ── Hive Boxes (untyped, namespaced por usuario activo) ────────
  /// Caja del usuario activo, o `null` si no está abierta.
  ///
  /// Los providers se pueden recrear en las transiciones de sesión (logout,
  /// cambio de cuenta) en el instante en que las cajas están cerradas a
  /// propósito: leerlas ahí lanzaba `HiveError: Box not found` y tumbaba la
  /// pantalla con un error a pantalla completa justo donde van los
  /// avistamientos (ver el fix en `_establishSession`, que además evita la
  /// ventana). Todo acceso pasa por acá: con la caja cerrada, las lecturas
  /// devuelven vacío y las escrituras no hacen nada — nunca un crash.
  Box? _tryBox(String base) {
    final name = _boxNameFor(base);
    return Hive.isBoxOpen(name) ? Hive.box(name) : null;
  }

  Box? get chaptersBox => _tryBox(AppConstants.chaptersBox);
  Box? get sightingsBox => _tryBox(AppConstants.sightingsBox);
  Box? get gamesBox => _tryBox(AppConstants.gamesBox);
  Box? get badgesBox => _tryBox(AppConstants.badgesBox);
  Box? get feedBox => _tryBox(AppConstants.feedBox);

  // ── Cache Chapters ───────────────────────────────────────────
  Future<void> cacheChapters(List<Map<String, dynamic>> chapters) async {
    final box = chaptersBox;
    if (box == null) return;
    await box.clear();
    for (var ch in chapters) {
      await box.put(ch['id'].toString(), ch);
    }
  }

  List<Map<String, dynamic>> getCachedChapters() {
    final box = chaptersBox;
    if (box == null) return [];
    return box.values
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Cache Badges ─────────────────────────────────────────────
  Future<void> cacheBadges(List<Map<String, dynamic>> badges) async {
    final box = badgesBox;
    if (box == null) return;
    await box.clear();
    for (var b in badges) {
      await box.put(b['id'].toString(), b);
    }
  }

  List<Map<String, dynamic>> getCachedBadges() {
    final box = badgesBox;
    if (box == null) return [];
    return box.values
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Cache Feed comunitario ───────────────────────────────────
  // Dos entradas fijas en vez de una caja "lista de N registros" — mismo
  // patrón simple que chapters/badges, pero aquí también guardamos cuándo
  // se cargó, para no repetir un refresco silencioso demasiado seguido
  // (ver AppConstants.feedRefreshMinInterval).
  static const _feedKey = 'community';
  static const _feedAtKey = 'community_at';

  Future<void> cacheCommunitySightings(
      List<Map<String, dynamic>> sightings) async {
    final box = feedBox;
    if (box == null) return;
    await box.put(_feedKey, sightings);
    await box.put(_feedAtKey, DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedCommunitySightings() {
    final box = feedBox;
    if (box == null) return [];
    final raw = box.get(_feedKey) as List?;
    if (raw == null) return [];
    return raw
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  DateTime? getCommunityCachedAt() {
    final box = feedBox;
    if (box == null) return null;
    final raw = box.get(_feedAtKey) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Offline Sighting Queue ───────────────────────────────────
  // `Box.add()` uses Hive's own auto-incrementing integer keys, so two
  // sightings queued in the same millisecond can't collide and silently
  // overwrite each other the way a `DateTime.now()`-derived string key did.
  Future<void> queueSighting(Map<String, dynamic> sighting) async {
    final box = sightingsBox;
    if (box == null) return;
    await box.add(sighting);
  }

  /// Keyed view of the queue, so a failed sync can delete just the entries
  /// that succeeded instead of clearing the whole box and re-inserting the
  /// ones that failed — that clear-then-reinsert had a window where an app
  /// kill between the two steps lost every pending sighting.
  Map<dynamic, Map<String, dynamic>> getPendingSightingsWithKeys() {
    final box = sightingsBox;
    if (box == null) return {};
    return box.toMap().map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        );
  }

  List<Map<String, dynamic>> getPendingSightings() =>
      getPendingSightingsWithKeys().values.toList();

  Future<void> removePendingSighting(dynamic key) async {
    final box = sightingsBox;
    if (box == null) return;
    await box.delete(key);
  }

  Future<void> clearPendingSightings() async {
    final box = sightingsBox;
    if (box == null) return;
    await box.clear();
  }

  // ── Fin de sesión ────────────────────────────────────────────
  /// Cierra la sesión actual: borra token y usuario, y cierra (sin
  /// vaciar) las cajas del usuario activo. Su caché sigue en disco para
  /// cuando esa misma cuenta vuelva a entrar en este dispositivo.
  ///
  /// Antes se llamaba `clearAll()` y sí vaciaba todo — el nombre nuevo
  /// refleja que ya no es un borrado total, solo de sesión.
  Future<void> clearSession() async {
    await clearUser();
    await clearToken();
    await _prefs.remove(AppConstants.activeUserIdKey);
    await closeUserBoxes();
  }

  /// Borrado real y total de los datos locales de una cuenta — usado por
  /// `deleteAccount()`, donde sí corresponde no dejar ni rastro en el
  /// dispositivo. `userId` puede ser distinto del activo si se llama tras
  /// haber cerrado ya la sesión.
  Future<void> purgeUserData(String userId) async {
    final wasActive = _activeUserId == userId;
    if (!wasActive) {
      // Abrir temporalmente solo para vaciar y cerrar.
      _activeUserId = userId;
    }
    for (final base in _boxNames) {
      final name = _boxNameFor(base);
      final box =
          Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
      await box.clear();
      await box.close();
    }
    for (final key in _prefs.getKeys()) {
      if (key.startsWith('first_game_start_${userId}_')) {
        await _prefs.remove(key);
      }
    }
    if (!wasActive) _activeUserId = null;
  }
}
