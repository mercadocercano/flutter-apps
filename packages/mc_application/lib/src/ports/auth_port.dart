/// Puerto de autenticación — el dominio dice QUÉ necesita,
/// la infraestructura dice CÓMO lo resuelve.
abstract interface class AuthPort {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> refreshToken(String refreshToken);
  Future<void> logout();
  Future<AuthSession?> getStoredSession();
  Future<void> storeSession(AuthSession session);
}

/// Sesión autenticada con tokens y tenant.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String tenantId;
  final String email;
  final String role;
  final DateTime expiresAt;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
