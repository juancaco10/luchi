import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/constants.dart';
import '../../../core/session/user_scoped_providers.dart';
import '../data/google_auth_service.dart';

// ── Auth Notifier ─────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthInitial()) {
    _checkSession();
  }

  final Ref _ref;

  /// `true` cuando el usuario omitió elegir apodo en esta sesión: el
  /// redirect de app.dart usa el apodo como puerta de una sola vez, y si
  /// no, "Omitir" en nickname_setup_screen no podría volver al home sin
  /// caer en un bucle. Se resetea en cada login — así la pregunta se
  /// repite hasta que el usuario elija o configure uno.
  bool nicknamePromptOmitted = false;

  /// `true` mientras el arranque refresca el perfil desde el backend
  /// (`GET /me`, ver `_refreshUserFromBackend`): la puerta del apodo en
  /// app.dart espera a ese refresco antes de decidir, para no preguntar un
  /// apodo que ya existe en el backend solo porque la caché local quedó
  /// vieja (p. ej. tras una reinstalación).
  bool refreshPending = false;

  Map<String, dynamic> _consentPayload() {
    final storage = LocalStorage.instance;
    return {
      'accepted': storage.parentalConsentDone,
      'timestamp': storage.parentalConsentAt,
      'policy_version': storage.parentalConsentPolicyVersion,
    };
  }

  void _checkSession() {
    if (!LocalStorage.instance.isInitialized) {
      state = const AuthUnauthenticated();
      return;
    }
    final userData = LocalStorage.instance.getUser();
    if (userData != null && LocalStorage.instance.isLoggedIn) {
      state = AuthAuthenticated(UserModel.fromJson(userData));
      // Debe quedar en true ANTES de disparar el refresco asíncrono: la
      // puerta del apodo en app.dart lee este flag en el mismo frame en
      // que se restaura la caché, y si no está ya en true para entonces,
      // decide con el perfil viejo sin esperar la respuesta de `GET /me`.
      refreshPending = true;
      _refreshUserFromBackend();
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// La caché local del perfil puede quedarse vieja (una reinstalación, un
  /// `PUT /me` que no llegó a guardarse en local, datos de antes de una
  /// migración): el backend es la fuente de verdad, así que al arrancar
  /// con sesión se re-lee el perfil completo (apodo, país, puntos...) y se
  /// actualizan estado y caché. Sin esto, la puerta del apodo volvía a
  /// preguntar un apodo que ya existe en el backend.
  ///
  /// Silencioso a propósito: sin red o con token inválido se queda con la
  /// caché local y el arranque sigue igual — el interceptor de errores ya
  /// tradujo el error y aquí NO se cierra la sesión (ver CLAUDE.md: cerrar
  /// sesión es responsabilidad del call site que depende de auth).
  Future<void> _refreshUserFromBackend() async {
    if (AppConstants.useMockAuth) {
      refreshPending = false;
      return;
    }
    try {
      final response = await _ref.read(apiClientProvider).get(ApiEndpoints.me);
      final data = response.data as Map<String, dynamic>;
      final fresh = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.instance.saveUser(fresh.toJson());
      state = AuthAuthenticated(fresh);
    } catch (_) {
      // Sin red o token inválido: se queda con la caché local.
    } finally {
      refreshPending = false;
    }
  }

  /// Punto único por el que toda cuenta entra a la app (login, registro,
  /// Google, invitado — mock incluido). Antes cada método guardaba token y
  /// usuario por su cuenta y listo; eso dejaba un agujero de multicuenta:
  /// si ya había una sesión de la cuenta A abierta y se iniciaba sesión
  /// con la cuenta B sin pasar por `logout()` primero (p. ej. Google
  /// reautenticando en silencio con otra cuenta), la caché en disco de A
  /// (avistamientos, capítulos, progreso de juegos) quedaba abierta y B
  /// podía verla como propia.
  ///
  /// Aquí se detecta el cambio de cuenta por `user.id` y, si lo hay, se
  /// limpia la sesión anterior (sin borrar su caché — sigue en disco para
  /// cuando esa cuenta vuelva a entrar) antes de abrir las cajas de la
  /// nueva.
  Future<void> _establishSession(UserModel user, String token) async {
    final previousUserId = LocalStorage.instance.activeUserId;
    final newUserId = user.id.toString();
    if (previousUserId != null && previousUserId != newUserId) {
      await LocalStorage.instance.clearSession();
    }
    await LocalStorage.instance.openUserBoxes(newUserId);
    await LocalStorage.instance.saveToken(token);
    await LocalStorage.instance.saveUser(user.toJson());
    if (previousUserId != null && previousUserId != newUserId) {
      // Invalida SOLO después de abrir las cajas del nuevo usuario y
      // guardar su token: la invalidación recrea los providers de sesión
      // (SightingsNotifier, GamesProgressNotifier, ...) y sus constructores
      // leen caché Hive de forma síncrona. Antes esta llamada iba entre
      // `clearSession()` y `openUserBoxes()`, así que los providers se
      // recreaban con las cajas cerradas y `HiveError: Box not found`
      // tumbaba el mapa de avistamientos con un error a pantalla completa
      // (además de disparar llamadas de red sin token).
      invalidateUserScopedProviders(_ref);
    }
    state = AuthAuthenticated(user);
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    nicknamePromptOmitted = false;

    if (AppConstants.useMockAuth) {
      return _mockLogin(email);
    }

    try {
      final response = await _ref.read(apiClientProvider).post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _establishSession(user, data['token'] as String);
      return true;
    } on DioException catch (e) {
      state = AuthError(
          (e.error as AppException?)?.message ?? 'No se pudo iniciar sesión.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AuthLoading();
    nicknamePromptOmitted = false;

    if (AppConstants.useMockAuth) {
      return _mockRegister(name, email);
    }

    try {
      final response = await _ref.read(apiClientProvider).post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'parental_consent': _consentPayload(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _establishSession(user, data['token'] as String);
      return true;
    } on DioException catch (e) {
      state = AuthError(
          (e.error as AppException?)?.message ?? 'No se pudo crear la cuenta.');
      return false;
    }
  }

  /// Intercambia un idToken de Google por la sesión propia del backend.
  /// El backend valida el token contra Google (firma, aud, email
  /// verificado) y devuelve exactamente {token, user} — mismo contrato
  /// que login(), así que no hace falta un AuthState nuevo para esto.
  Future<bool> loginConGoogle(String idToken) async {
    state = const AuthLoading();
    nicknamePromptOmitted = false;

    if (AppConstants.useMockAuth) {
      return _mockLogin('google@luciernagas.com');
    }

    try {
      final response = await _ref.read(apiClientProvider).post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken, 'parental_consent': _consentPayload()},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _establishSession(user, data['token'] as String);
      return true;
    } on DioException catch (e) {
      state = AuthError(
        (e.error as AppException?)?.message ??
            'No se pudo iniciar sesión con Google.',
      );
      return false;
    }
  }

  Future<bool> loginInvitado() async {
    state = const AuthLoading();
    nicknamePromptOmitted = false;

    if (AppConstants.useMockAuth) {
      return _mockLogin('invitado@luciernagas.com');
    }

    try {
      final response = await _ref.read(apiClientProvider).post(
        ApiEndpoints.guestLogin,
        data: {'parental_consent': _consentPayload()},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _establishSession(user, data['token'] as String);
      return true;
    } on DioException catch (e) {
      state = AuthError(
        (e.error as AppException?)?.message ??
            'No se pudo iniciar como invitado.',
      );
      return false;
    }
  }

  // ── Mock auth (AppConstants.useMockAuth == true, the default until a
  // real backend is deployed — see docs/BACKEND_AUDIT.md). Lets the rest of
  // the app be demoed/tested without a working API. ────────────────────
  Future<bool> _mockLogin(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final mockUser = UserModel(
      id: 1,
      name: 'Juan',
      email: email.isNotEmpty ? email : 'demo@luciernagas.com',
      points: 120,
      level: 2,
      levelName: 'Explorador',
    );

    await _establishSession(mockUser, 'mock_token_123');
    return true;
  }

  Future<bool> _mockRegister(String name, String email) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final mockUser = UserModel(
      id: 2,
      name: name.isNotEmpty ? name : 'Nuevo Guardián',
      email: email.isNotEmpty ? email : 'demo@luciernagas.com',
      points: 0,
      level: 1,
      levelName: 'Observador',
    );

    await _establishSession(mockUser, 'mock_token_123');
    return true;
  }

  /// Re-reads the local session so the UI updates after background syncs.
  void refreshSession() => _checkSession();

  Future<void> logout() async {
    nicknamePromptOmitted = false;
    await LocalStorage.instance.clearSession();
    invalidateUserScopedProviders(_ref);
    state = const AuthUnauthenticated();
    // Cierra la sesión del SDK de Google: sin esto, `authenticate()`
    // reautentica en silencio con la última cuenta usada y el selector de
    // cuentas nunca vuelve a aparecer, impidiendo entrar con una segunda
    // cuenta Google en el mismo dispositivo.
    try {
      await GoogleAuthService.instance.signOut();
    } catch (_) {
      // No hay sesión de Google activa (login por email/invitado) o el
      // SDK no está inicializado: no debe bloquear el logout normal.
    }
  }

  Future<bool> deleteAccount() async {
    state = const AuthLoading();
    final userId = LocalStorage.instance.activeUserId;
    try {
      if (!AppConstants.useMockAuth) {
        await _ref.read(apiClientProvider).delete(ApiEndpoints.me);
      }
    } catch (_) {
      final user = LocalStorage.instance.getUser();
      if (user != null) {
        state = AuthAuthenticated(UserModel.fromJson(user));
      } else {
        state = const AuthUnauthenticated();
      }
      return false;
    }

    await LocalStorage.instance.clearSession();
    if (userId != null) {
      await LocalStorage.instance.purgeUserData(userId);
    }
    invalidateUserScopedProviders(_ref);
    state = const AuthUnauthenticated();
    try {
      await GoogleAuthService.instance.signOut();
    } catch (_) {}
    return true;
  }

  /// Add points to current user (local update + persist)
  Future<void> addPoints(int pts) async {
    final current = state;
    if (current is AuthAuthenticated) {
      final user = current.user;
      final updated = user.copyWith(
        points: user.points + pts,
        level: AppConstants.getLevelForPoints(user.points + pts),
        levelName: AppConstants.getLevelName(user.points + pts),
      );
      if (LocalStorage.instance.isInitialized) {
        await LocalStorage.instance.saveUser(updated.toJson());
      }
      state = AuthAuthenticated(updated);
    }
  }

  /// Guarda país/ciudad — requisito único antes de publicar el primer
  /// avistamiento (ver location_setup_screen.dart) y editable después
  /// desde ajustes. A diferencia de `addPoints`, sí hay backend real que
  /// actualizar: sin el `PUT /me`, el dato se perdería al reinstalar o
  /// cambiar de dispositivo, ya que hoy no hay forma de recuperarlo.
  Future<bool> updateLocation(
      {required String country, required String city}) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;

    if (AppConstants.useMockAuth) {
      final updated = current.user.copyWith(country: country, city: city);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    }

    try {
      final response = await _ref.read(apiClientProvider).put(
        ApiEndpoints.me,
        data: {'country': country, 'city': city},
      );
      final data = response.data as Map<String, dynamic>;
      final updated = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cambia el avatar del perfil a uno de los 18 predefinidos en
  /// `assets/images/avatars/` (ver `AvatarPickerSheet`). Se guarda solo el
  /// nombre de archivo (`avatar07.png`), nunca una ruta completa — el
  /// backend valida contra esa misma lista blanca en `PUT /me`, así que
  /// esto no es más que la mitad cliente de esa comprobación.
  Future<bool> updateAvatar(String fileName) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;

    if (AppConstants.useMockAuth) {
      final updated = current.user.copyWith(avatarUrl: fileName);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    }

    try {
      final response = await _ref.read(apiClientProvider).put(
        ApiEndpoints.me,
        data: {'avatar_url': fileName},
      );
      final data = response.data as Map<String, dynamic>;
      final updated = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Guarda el apodo elegido en `nickname_setup_screen.dart` (cómo quiere
  /// que lo llamen en el feed y la app). El backend valida el mismo límite
  /// que `AppConstants.maxNicknameLength` en `PUT /me`.
  Future<bool> updateNickname(String nickname) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;

    final trimmed = nickname.trim();
    if (trimmed.isEmpty || trimmed.length > AppConstants.maxNicknameLength) {
      return false;
    }

    if (AppConstants.useMockAuth) {
      final updated = current.user.copyWith(nickname: trimmed);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    }

    try {
      final response = await _ref.read(apiClientProvider).put(
        ApiEndpoints.me,
        data: {'nickname': trimmed},
      );
      final data = response.data as Map<String, dynamic>;
      final updated = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});
