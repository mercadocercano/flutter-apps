import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestión de tokens JWT para mc_admin.
/// Persiste en flutter_secure_storage (localStorage en web).
class AuthHelper {
  AuthHelper._();

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'mc_admin_auth', publicKey: 'mc_admin'),
  );
  static const _keyAccessToken = 'mc_admin_access_token';
  static const _keyRefreshToken = 'mc_admin_refresh_token';

  // In-memory cache para evitar I/O en cada request
  static String? _jwt;
  static String? _refreshToken;
  static String? _tenantId;
  static String? _userId;

  /// Inicializa la sesión desde storage persistido. Llamar en main() antes de runApp.
  static Future<void> init() async {
    final jwt = await _storage.read(key: _keyAccessToken);
    final refresh = await _storage.read(key: _keyRefreshToken);
    if (jwt != null && !isExpired(jwt)) {
      _jwt = jwt;
      _refreshToken = refresh;
      _tenantId = _extractTenantId(jwt);
      _userId = _extractUserId(jwt);
    } else {
      await clearTokens();
    }
  }

  static Future<void> setTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _jwt = accessToken;
    _refreshToken = refreshToken;
    _tenantId = _extractTenantId(accessToken);
    _userId = _extractUserId(accessToken);
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  /// Compat: usado por código existente que sólo pasa el access token.
  static Future<void> setJwtAsync(String jwt, {String? refreshToken}) =>
      setTokens(accessToken: jwt, refreshToken: refreshToken);

  /// Sync read — usa cache in-memory.
  static String? getJwt() => _jwt;

  static String? getRefreshToken() => _refreshToken;

  static String? getTenantId() => _tenantId;

  /// Identificador del usuario autenticado (claim `sub` del JWT).
  /// Se propaga como `X-Operator-Id` en operaciones de administración.
  static String? getUserId() => _userId;

  static bool isAuthenticated() => _jwt != null && !isExpired(_jwt);

  static Future<void> clearTokens() async {
    _jwt = null;
    _refreshToken = null;
    _tenantId = null;
    _userId = null;
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Mantiene compat con código existente (sync).
  static void clearJwt() {
    _jwt = null;
    _refreshToken = null;
    _tenantId = null;
    _userId = null;
    // Fire-and-forget async clean — acceptable para logout
    _storage.delete(key: _keyAccessToken);
    _storage.delete(key: _keyRefreshToken);
  }

  static bool isValidJwt(String? jwt) {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return false;
      final payload = _decodePayload(parts[1]);
      return payload.containsKey('sub') && payload.containsKey('exp');
    } catch (_) {
      return false;
    }
  }

  static bool isExpired(String? jwt) {
    if (jwt == null) return true;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = _decodePayload(parts[1]);
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      // 30s buffer para refrescar antes de que expire
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= (exp - 30);
    } catch (_) {
      return true;
    }
  }

  static String? _extractTenantId(String jwt) {
    try {
      final payload = _decodePayload(jwt.split('.')[1]);
      return payload['tenant_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String? _extractUserId(String jwt) {
    try {
      final payload = _decodePayload(jwt.split('.')[1]);
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodePayload(String base64Segment) {
    final normalized = base64Segment.padRight(
      base64Segment.length + (4 - base64Segment.length % 4) % 4,
      '=',
    );
    return Map<String, dynamic>.from(
      jsonDecode(String.fromCharCodes(base64Url.decode(normalized))),
    );
  }
}
