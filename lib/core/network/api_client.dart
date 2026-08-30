import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../utils/constants.dart';
import '../storage/local_storage.dart';

/// Thin wrapper around Dio. Built once by [apiClientProvider] so it can be
/// injected — and, in tests, replaced by overriding [dioProvider] with a
/// mock adapter instead of hitting the network. No more `ApiClient.instance`
/// singleton: every caller reads it from Riverpod.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) => _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) => _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) => _dio.delete<T>(path, options: options);

  /// `_buildDio()` fija `Content-Type: application/json` globalmente, así
  /// que una subida de archivo necesita pisar ese header explícitamente
  /// con `multipart/form-data` — de ahí este método aparte en vez de
  /// reutilizar `post` con un `FormData` a secas.
  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData formData,
  }) => _dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
}

Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(),
    _LoggingInterceptor(Logger()),
    _ErrorInterceptor(),
  ]);

  return dio;
}

final dioProvider = Provider<Dio>((ref) => _buildDio());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

// ── Auth Token Injection ──────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.instance.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ── Logging ──────────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  final Logger _logger;
  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✗ ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}

// ── Global Error Handling ─────────────────────────────────────────
//
// This interceptor's only job is to turn a DioException into an
// AppException with a message worth showing a child. It does NOT decide
// whether the session ends.
//
// It used to call `LocalStorage.instance.clearToken()` on *any* 401,
// which meant a single failed request on any screen (a flaky connection,
// a backend hiccup) silently logged the user out mid-lesson — confirmed
// on-device: opening "Nivel 1" while the token happened to be stale threw
// the child back to the login screen with no explanation. See CLAUDE.md.
//
// There is currently one session-check call: `GET /me` at cold start,
// used only to refresh the local profile cache (`auth_provider.dart`
// `_refreshUserFromBackend`). It deliberately does NOT end the session on
// 401 (offline or stale token just keeps the cache). `ApiEndpoints.me` is
// otherwise only used for `DELETE` (delete account). So there is no call
// site today where "the session is definitely dead" can be inferred from a
// bare 401 fired from who-knows-which screen. Ending a session belongs to
// the call site that actually depends on auth state — login/register
// failure, or `deleteAccount()`, which already handles its own error path.
// If another real session-validation endpoint is added later, its call
// site should call `authProvider.notifier.logout()` explicitly in its
// `catch`, the same way `deleteAccount()` does today.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _backendMessage(err.response?.data) ?? _fallbackMessage(err);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException(message, err.response?.statusCode),
      ),
    );
  }

  /// The backend already returns `{"error": "texto legible en español"}`
  /// on failure (see docs/BACKEND_AUDIT.md) — use it instead of a generic
  /// "Error del servidor (400)." that throws away exactly the information
  /// the child needs (e.g. "Correo y contraseña son requeridos").
  String? _backendMessage(dynamic data) {
    if (data is Map && data['error'] is String) {
      final msg = data['error'] as String;
      return msg.isEmpty ? null : msg;
    }
    return null;
  }

  String _fallbackMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado. Verifica tu internet.';
      case DioExceptionType.connectionError:
        return 'Sin conexión a internet.';
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        if (code == 401) return 'No autorizado. Inicia sesión de nuevo.';
        if (code == 422) return 'Datos inválidos.';
        return 'Error del servidor ($code).';
      default:
        return 'Error inesperado. Intenta de nuevo.';
    }
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
