import 'dart:convert';

class AuthHelper {
  AuthHelper._();

  static String? _jwt;
  static String? _tenantId;

  static void setJwt(String jwt) {
    _jwt = jwt;
    _tenantId = _extractTenantId(jwt);
  }

  static String? getJwt() => _jwt;

  static String? getTenantId() => _tenantId;

  static void clearJwt() {
    _jwt = null;
    _tenantId = null;
  }

  static bool isValidJwt(String? jwt) {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return false;
      final payload = _decodePayload(parts[1]);
      return payload.containsKey('sub') &&
          payload.containsKey('exp') &&
          payload.containsKey('tenant_id');
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
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true;
    }
  }

  static String? _extractTenantId(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = _decodePayload(parts[1]);
      return payload['tenant_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodePayload(String base64Segment) {
    final normalized = base64Segment.padRight(
      base64Segment.length + (4 - base64Segment.length % 4) % 4,
      '=',
    );
    final decoded = String.fromCharCodes(base64Url.decode(normalized));
    return Map<String, dynamic>.from(jsonDecode(decoded));
  }
}
