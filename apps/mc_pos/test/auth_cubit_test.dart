import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_pos/features/auth/auth_cubit.dart';

/// Mock del AuthPort para tests.
class FakeAuthPort implements AuthPort {
  AuthSession? storedSession;
  bool loginShouldFail = false;
  String loginError = 'Test error';

  @override
  Future<AuthSession> login(String email, String password) async {
    if (loginShouldFail) throw Exception(loginError);
    final session = AuthSession(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      userId: 'user-123',
      tenantId: 'tenant-456',
      email: email,
      role: 'owner',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    storedSession = session;
    return session;
  }

  @override
  Future<AuthSession> refreshToken(String refreshToken) async {
    return AuthSession(
      accessToken: 'refreshed-token',
      refreshToken: 'new-refresh-token',
      userId: 'user-123',
      tenantId: 'tenant-456',
      email: 'test@test.com',
      role: 'owner',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> logout() async {
    storedSession = null;
  }

  @override
  Future<AuthSession?> getStoredSession() async => storedSession;

  @override
  Future<void> storeSession(AuthSession session) async {
    storedSession = session;
  }
}

void main() {
  group('AuthCubit', () {
    late FakeAuthPort authPort;
    late AuthCubit cubit;

    setUp(() {
      authPort = FakeAuthPort();
      cubit = AuthCubit(authPort);
    });

    tearDown(() => cubit.close());

    test('estado inicial es AuthInitial', () {
      expect(cubit.state, isA<AuthInitial>());
    });

    blocTest<AuthCubit, AuthState>(
      'login exitoso emite [AuthLoading, AuthSuccess]',
      build: () => AuthCubit(authPort),
      act: (c) => c.login('test@test.com', 'password123'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
      verify: (c) {
        final state = c.state as AuthSuccess;
        expect(state.session.email, 'test@test.com');
        expect(state.session.tenantId, 'tenant-456');
        expect(state.session.accessToken, 'test-access-token');
      },
    );

    blocTest<AuthCubit, AuthState>(
      'login fallido emite [AuthLoading, AuthError]',
      build: () {
        authPort.loginShouldFail = true;
        return AuthCubit(authPort);
      },
      act: (c) => c.login('bad@email.com', 'wrong'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
      verify: (c) {
        final state = c.state as AuthError;
        expect(state.message, isNotEmpty);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'checkSession sin sesión guardada no cambia estado',
      build: () => AuthCubit(authPort),
      act: (c) => c.checkSession(),
      expect: () => [],
    );

    blocTest<AuthCubit, AuthState>(
      'checkSession con sesión válida emite AuthSuccess',
      build: () {
        authPort.storedSession = AuthSession(
          accessToken: 'stored-token',
          refreshToken: 'stored-refresh',
          userId: 'user-123',
          tenantId: 'tenant-456',
          email: 'stored@test.com',
          role: 'owner',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        return AuthCubit(authPort);
      },
      act: (c) => c.checkSession(),
      expect: () => [isA<AuthSuccess>()],
    );

    blocTest<AuthCubit, AuthState>(
      'logout emite AuthInitial',
      build: () => AuthCubit(authPort),
      seed: () => AuthSuccess(AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        userId: 'user-123',
        tenantId: 'tenant-456',
        email: 'test@test.com',
        role: 'owner',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      )),
      act: (c) => c.logout(),
      expect: () => [isA<AuthInitial>()],
    );

    group('AuthSessionProvider', () {
      test('getSession devuelve sesión cuando está autenticado', () async {
        await cubit.login('test@test.com', 'pass');
        final session = await cubit.getSession();
        expect(session, isNotNull);
        expect(session!.email, 'test@test.com');
      });

      test('getSession devuelve null cuando no está autenticado', () async {
        final session = await cubit.getSession();
        expect(session, isNull);
      });
    });
  });
}
