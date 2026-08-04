import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/constants.dart';

// ── Auth Notifier ─────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthInitial()) {
    _checkSession();
  }

  final Ref _ref;

  void _checkSession() {
    final userData = LocalStorage.instance.getUser();
    if (userData != null && LocalStorage.instance.isLoggedIn) {
      state = AuthAuthenticated(UserModel.fromJson(userData));
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();

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
      await LocalStorage.instance.saveToken(data['token'] as String);
      await LocalStorage.instance.saveUser(user.toJson());
      state = AuthAuthenticated(user);
      return true;
    } on DioException catch (e) {
      state = AuthError((e.error as AppException?)?.message ?? 'No se pudo iniciar sesión.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AuthLoading();

    if (AppConstants.useMockAuth) {
      return _mockRegister(name, email);
    }

    try {
      final response = await _ref.read(apiClientProvider).post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await LocalStorage.instance.saveToken(data['token'] as String);
      await LocalStorage.instance.saveUser(user.toJson());
      state = AuthAuthenticated(user);
      return true;
    } on DioException catch (e) {
      state = AuthError((e.error as AppException?)?.message ?? 'No se pudo crear la cuenta.');
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

    await LocalStorage.instance.saveToken('mock_token_123');
    await LocalStorage.instance.saveUser(mockUser.toJson());

    state = AuthAuthenticated(mockUser);
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

    await LocalStorage.instance.saveToken('mock_token_123');
    await LocalStorage.instance.saveUser(mockUser.toJson());

    state = AuthAuthenticated(mockUser);
    return true;
  }

  /// Re-reads the local session so the UI updates after background syncs.
  void refreshSession() => _checkSession();

  Future<void> logout() async {
    await LocalStorage.instance.clearAll();
    state = const AuthUnauthenticated();
  }

  Future<bool> deleteAccount() async {
    state = const AuthLoading();
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

    await LocalStorage.instance.clearAll();
    state = const AuthUnauthenticated();
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
      await LocalStorage.instance.saveUser(updated.toJson());
      state = AuthAuthenticated(updated);
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
