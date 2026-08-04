import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../utils/constants.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _logger = Logger();

  ApiClient._() {
    _dio = Dio(
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

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(_logger),
      _ErrorInterceptor(),
    ]);
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;

  // ── Convenience Methods ───────────────────────────────────────

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
}

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

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Tiempo de conexión agotado. Verifica tu internet.';
        break;
      case DioExceptionType.connectionError:
        message = 'Sin conexión a internet.';
        break;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        if (code == 401) {
          message = 'Sesión expirada. Inicia sesión de nuevo.';
          LocalStorage.instance.clearToken();
        } else if (code == 422) {
          message = 'Datos inválidos.';
        } else {
          message = 'Error del servidor ($code).';
        }
        break;
      default:
        message = 'Error inesperado. Intenta de nuevo.';
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException(message, err.response?.statusCode),
      ),
    );
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
