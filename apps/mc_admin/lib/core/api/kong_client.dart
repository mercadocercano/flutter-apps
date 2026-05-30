import 'package:dio/dio.dart';

import 'auth_helper.dart';

/// Cliente HTTP singleton para Kong Gateway.
/// Base URL configurable vía kKongBaseUrl (override en tests).
/// Intercepta 401 → intenta refresh → reintenta request original.
class KongClient {
  KongClient._internal();
  static final KongClient _instance = KongClient._internal();
  factory KongClient() => _instance;

  // ignore: prefer_const_constructors — permite override en tests
  static String kKongBaseUrl =
      const String.fromEnvironment('KONG_BASE_URL', defaultValue: 'http://localhost:8001');

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: kKongBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));

    return dio;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final jwt = AuthHelper.getJwt();
    if (jwt != null) {
      options.headers['Authorization'] = 'Bearer $jwt';
      options.headers['X-User-Role'] = 'marketplace_admin';
    }
    final tenantId = AuthHelper.getTenantId();
    if (tenantId != null) {
      options.headers['X-Tenant-ID'] = tenantId;
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Reintenta el request original con el nuevo token
        final retryOptions = error.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer ${AuthHelper.getJwt()}';
        try {
          final response = await _dio.fetch(retryOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // Refresh OK pero retry falló — propagar error
        }
      }
      // Sin refresh o refresh fallido → limpiar sesión
      AuthHelper.clearJwt();
    }
    handler.next(error);
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = AuthHelper.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final dio = Dio(BaseOptions(baseUrl: kKongBaseUrl));
      final response = await dio.post<Map<String, dynamic>>(
        '/iam/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final accessToken = response.data?['access_token'] as String?;
      final newRefresh = response.data?['refresh_token'] as String?;
      if (accessToken == null) return false;
      await AuthHelper.setTokens(
        accessToken: accessToken,
        refreshToken: newRefresh ?? refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
