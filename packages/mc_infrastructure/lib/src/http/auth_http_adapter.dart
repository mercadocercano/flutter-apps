import 'package:dio/dio.dart';
import 'package:mc_application/mc_application.dart';
import '../storage/secure_session_storage.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del AuthPort — habla con iam-service via Kong.
/// Usa Dio directo (no McHttpClient) porque el login no tiene sesión aún.
class AuthHttpAdapter implements AuthPort {
  final Dio _dio;
  final SecureSessionStorage _storage;

  AuthHttpAdapter({
    required String baseUrl,
    required SecureSessionStorage storage,
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )),
        _storage = storage;

  @override
  Future<AuthSession> login(String email, String password) async {
    final response = await _dio.post(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
        'provider': 'LOCAL',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final expiresIn = data['expires_in'] as int? ?? 3600;

    final session = AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      userId: user['id'] as String,
      tenantId: user['tenant_id'] as String,
      email: user['email'] as String,
      role: user['role_id'] as String? ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );

    await _storage.saveSession(session);
    return session;
  }

  /// Parsea la respuesta del onboarding-service (estructura diferente al login).
  /// Lanza excepción descriptiva si success=false.
  AuthSession _parseOnboardingResponse(Map<String, dynamic> data) {
    if (data['success'] == false) {
      final msg = data['message'] as String? ?? 'Error en el registro';
      throw Exception(msg);
    }
    final userData = data['user_data'] as Map<String, dynamic>;
    final tenantId = data['tenant_id'] as String;

    return AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      userId: userData['id'] as String,
      tenantId: tenantId,
      email: userData['email'] as String,
      role: userData['role'] as String? ?? '',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? storeName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.onboardingRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': password,
        if (storeName != null && storeName.isNotEmpty) 'store_name': storeName,
      },
    );

    final session = _parseOnboardingResponse(
      response.data as Map<String, dynamic>,
    );
    await _storage.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiEndpoints.authRefresh,
      data: {'refresh_token': refreshToken},
    );

    final data = response.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final expiresIn = data['expires_in'] as int? ?? 3600;

    final session = AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      userId: user['id'] as String,
      tenantId: user['tenant_id'] as String,
      email: user['email'] as String,
      role: user['role_id'] as String? ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );

    await _storage.saveSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final session = await _storage.loadSession();
    if (session != null) {
      try {
        _dio.options.headers['Authorization'] =
            'Bearer ${session.accessToken}';
        await _dio.post(ApiEndpoints.authLogout);
      } catch (_) {
        // Logout del servidor falla silenciosamente — igual limpiamos local
      }
    }
    await _storage.clearSession();
  }

  @override
  Future<AuthSession?> getStoredSession() => _storage.loadSession();

  @override
  Future<void> storeSession(AuthSession session) =>
      _storage.saveSession(session);
}
