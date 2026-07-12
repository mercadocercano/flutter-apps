import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_admin/core/api/auth_helper.dart';

const _channel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock permanente durante toda la suite — evita fire-and-forget race
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      return switch (call.method) {
        'read' => null,
        'write' => null,
        'delete' => null,
        'deleteAll' => null,
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  // JWT válido con exp muy lejano (año 2099)
  // payload: {"sub":"u1","exp":4102444800,"tenant_id":"t1"}
  const validJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiJ1MSIsImV4cCI6NDEwMjQ0NDgwMCwidGVuYW50X2lkIjoidDEifQ'
      '.signature';

  // JWT expirado (exp: 1000000 — epoch 2001)
  const expiredJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiJ1MSIsImV4cCI6MTAwMDAwMCwidGVuYW50X2lkIjoidDEifQ'
      '.signature';

  group('AuthHelper', () {
    tearDown(() => AuthHelper.clearJwt());

    group('isValidJwt', () {
      test('retorna true para JWT bien formado', () {
        expect(AuthHelper.isValidJwt(validJwt), isTrue);
      });

      test('retorna false para null', () {
        expect(AuthHelper.isValidJwt(null), isFalse);
      });

      test('retorna false para string vacío', () {
        expect(AuthHelper.isValidJwt(''), isFalse);
      });

      test('retorna false para string sin 3 partes', () {
        expect(AuthHelper.isValidJwt('solo.dos'), isFalse);
      });
    });

    group('isExpired', () {
      test('retorna false para JWT con exp futuro', () {
        expect(AuthHelper.isExpired(validJwt), isFalse);
      });

      test('retorna true para JWT con exp pasado', () {
        expect(AuthHelper.isExpired(expiredJwt), isTrue);
      });

      test('retorna true para null', () {
        expect(AuthHelper.isExpired(null), isTrue);
      });
    });

    group('setTokens y clearJwt (in-memory cache)', () {
      test('getJwt retorna null antes de setTokens', () {
        expect(AuthHelper.getJwt(), isNull);
      });

      test('setTokens actualiza cache in-memory', () async {
        await AuthHelper.setTokens(
          accessToken: validJwt,
          refreshToken: 'refresh123',
        );
        expect(AuthHelper.getJwt(), equals(validJwt));
        expect(AuthHelper.getRefreshToken(), equals('refresh123'));
      });

      test('clearJwt limpia cache', () async {
        await AuthHelper.setTokens(accessToken: validJwt);
        AuthHelper.clearJwt();
        expect(AuthHelper.getJwt(), isNull);
        expect(AuthHelper.getRefreshToken(), isNull);
      });
    });

    group('getTenantId', () {
      test('extrae tenant_id del JWT válido', () async {
        await AuthHelper.setTokens(accessToken: validJwt);
        expect(AuthHelper.getTenantId(), equals('t1'));
      });

      test('retorna null cuando no hay JWT', () {
        expect(AuthHelper.getTenantId(), isNull);
      });
    });

    group('getUserId', () {
      test('extrae sub del JWT válido', () async {
        await AuthHelper.setTokens(accessToken: validJwt);
        expect(AuthHelper.getUserId(), equals('u1'));
      });

      test('retorna null cuando no hay JWT', () {
        expect(AuthHelper.getUserId(), isNull);
      });
    });

    group('isAuthenticated', () {
      test('retorna false cuando no hay JWT', () {
        expect(AuthHelper.isAuthenticated(), isFalse);
      });

      test('retorna true con JWT válido', () async {
        await AuthHelper.setTokens(accessToken: validJwt);
        expect(AuthHelper.isAuthenticated(), isTrue);
      });

      test('retorna false con JWT expirado', () async {
        await AuthHelper.setTokens(accessToken: expiredJwt);
        expect(AuthHelper.isAuthenticated(), isFalse);
      });
    });
  });
}
