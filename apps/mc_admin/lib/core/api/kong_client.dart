import 'package:dio/dio.dart';

import 'auth_helper.dart';

class KongClient {
  KongClient._internal();
  static final KongClient _instance = KongClient._internal();
  factory KongClient() => _instance;

  static const String _baseUrl = 'http://localhost:8001';

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
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
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
