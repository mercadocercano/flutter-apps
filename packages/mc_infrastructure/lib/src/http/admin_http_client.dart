import 'package:dio/dio.dart';

import '../auth/admin_auth_helper.dart';

/// Cliente HTTP singleton para Kong Gateway (mc_admin).
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
      // 20s (no 10s) para tolerar el cold-start del backend: si un servicio
      // estuvo idle, la 1ª request puede tardar varios segundos (pim cold ~6.7s
      // observado) y con 10s se tiraba `DioException [connection timeout]` en
      // pantallas como Quickstart → Templates. Warm responde en ~0.5s.
      connectTimeout: const Duration(seconds: 20),
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
    // Respetar un X-Tenant-ID explícito de la request (p.ej. "global" para
    // vistas de plataforma); solo caer al del helper si no vino seteado.
    final tenantId = AuthHelper.getTenantId();
    if (tenantId != null) {
      options.headers.putIfAbsent('X-Tenant-ID', () => tenantId);
    }
    // Propagar identidad del operador para operaciones de administración auditadas.
    final userId = AuthHelper.getUserId();
    if (userId != null) {
      options.headers.putIfAbsent('X-Operator-Id', () => userId);
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

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      );

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
