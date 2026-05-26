import 'package:dio/dio.dart';
import 'package:mc_application/mc_application.dart';

/// Cliente HTTP de Mercado Cercano.
/// Habla con Kong Gateway, inyecta Authorization y X-Tenant-ID automáticamente.
///
/// Portado del patrón de base-api-client.ts del frontend Next.js.
class McHttpClient {
  final Dio _dio;

  McHttpClient({
    required String baseUrl,
    required AuthSessionProvider sessionProvider,
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(_AuthInterceptor(_dio, sessionProvider));
  }

  /// GET con path relativo al baseUrl.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get(path, queryParameters: queryParameters);

  /// POST con body JSON.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) =>
      _dio.post(path, data: data);

  /// PUT con body JSON.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
  }) =>
      _dio.put(path, data: data);

  /// PATCH con body JSON opcional.
  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch(path, data: data);

  /// DELETE.
  Future<Response<T>> delete<T>(String path) => _dio.delete(path);
}

/// Interfaz para obtener la sesión actual (token + tenant).
abstract interface class AuthSessionProvider {
  Future<AuthSession?> getSession();
  /// Intenta renovar el access token con el refresh token.
  /// Retorna la nueva sesión o null si falló.
  Future<AuthSession?> refreshSession();
  Future<void> onSessionExpired();
}

/// Interceptor que agrega Authorization y X-Tenant-ID a cada request.
/// En caso de 401, intenta refresh automático y reintenta el request original.
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final AuthSessionProvider _sessionProvider;

  _AuthInterceptor(this._dio, this._sessionProvider);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _sessionProvider.getSession();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      options.headers['X-Tenant-ID'] = session.tenantId;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isRetry = err.requestOptions.extra['_retry'] == true;
    if (err.response?.statusCode == 401 && !isRetry) {
      final newSession = await _sessionProvider.refreshSession();
      if (newSession != null) {
        err.requestOptions.headers['Authorization'] =
            'Bearer ${newSession.accessToken}';
        err.requestOptions.extra['_retry'] = true;
        try {
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
      await _sessionProvider.onSessionExpired();
    }
    handler.next(err);
  }
}
