import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mc_application/mc_application.dart';

/// Persistencia segura de la sesión JWT.
/// Usa Keychain (iOS) / EncryptedSharedPreferences (Android).
class SecureSessionStorage {
  static const _keyAccessToken = 'mc_access_token';
  static const _keyRefreshToken = 'mc_refresh_token';
  static const _keyUserId = 'mc_user_id';
  static const _keyTenantId = 'mc_tenant_id';
  static const _keyEmail = 'mc_email';
  static const _keyRole = 'mc_role';
  static const _keyExpiresAt = 'mc_expires_at';

  final FlutterSecureStorage _storage;

  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: session.accessToken),
      _storage.write(key: _keyRefreshToken, value: session.refreshToken),
      _storage.write(key: _keyUserId, value: session.userId),
      _storage.write(key: _keyTenantId, value: session.tenantId),
      _storage.write(key: _keyEmail, value: session.email),
      _storage.write(key: _keyRole, value: session.role),
      _storage.write(
        key: _keyExpiresAt,
        value: session.expiresAt.toIso8601String(),
      ),
    ]);
  }

  Future<AuthSession?> loadSession() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    if (accessToken == null) return null;

    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final userId = await _storage.read(key: _keyUserId);
    final tenantId = await _storage.read(key: _keyTenantId);
    final email = await _storage.read(key: _keyEmail);
    final role = await _storage.read(key: _keyRole);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);

    if (refreshToken == null || userId == null || tenantId == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      tenantId: tenantId,
      email: email ?? '',
      role: role ?? '',
      expiresAt: DateTime.tryParse(expiresAtStr ?? '') ?? DateTime.now(),
    );
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
