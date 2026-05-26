import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_infrastructure/mc_infrastructure.dart';

/// Estados de autenticación.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final AuthSession session;
  const AuthSuccess(this.session);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Cubit de autenticación — maneja login, logout, y sesión persistida.
/// Implementa [AuthSessionProvider] para que McHttpClient inyecte tokens.
class AuthCubit extends Cubit<AuthState> implements AuthSessionProvider {
  final AuthPort _authPort;

  AuthCubit(this._authPort) : super(const AuthInitial());

  /// Intenta restaurar sesión guardada al arrancar.
  Future<void> checkSession() async {
    try {
      debugPrint('[AuthCubit] checkSession: buscando sesión guardada...');
      final session = await _authPort.getStoredSession()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('[AuthCubit] checkSession: timeout al leer storage');
        return null;
      });
      if (session == null) {
        debugPrint('[AuthCubit] checkSession: no hay sesión guardada');
        return;
      }

      if (session.isExpired) {
        debugPrint('[AuthCubit] checkSession: sesión expirada, limpiando...');
        await _authPort.logout();
        return;
      }

      debugPrint('[AuthCubit] checkSession: sesión válida, tenantId=${session.tenantId}');
      emit(AuthSuccess(session));
    } catch (e) {
      debugPrint('[AuthCubit] checkSession: error: $e');
    }
  }

  Future<void> login(String email, String password) async {
    debugPrint('[AuthCubit] login: intentando con $email...');
    emit(const AuthLoading());
    try {
      final session = await _authPort.login(email, password);
      debugPrint('[AuthCubit] login: éxito, tenantId=${session.tenantId}');
      emit(AuthSuccess(session));
    } catch (e) {
      debugPrint('[AuthCubit] login: error: $e');
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? storeName,
  }) async {
    debugPrint('[AuthCubit] register: intentando con $email...');
    emit(const AuthLoading());
    try {
      final session = await _authPort.register(
        name: name,
        email: email,
        password: password,
        storeName: storeName,
      );
      debugPrint('[AuthCubit] register: éxito, tenantId=${session.tenantId}');
      emit(AuthSuccess(session));
    } catch (e) {
      debugPrint('[AuthCubit] register: error: $e');
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> logout() async {
    await _authPort.logout();
    emit(const AuthInitial());
  }

  String _parseError(Object e) {
    final message = e.toString();
    if (message.contains('401')) return 'Email o contraseña incorrectos';
    if (message.contains('404')) return 'Usuario no encontrado';
    if (message.contains('409')) return 'Ya existe una cuenta con ese email';
    if (message.contains('429')) return 'Demasiados intentos. Esperá un momento';
    if (message.contains('SocketException') || message.contains('Connection')) {
      return 'Error de conexión. Verificá tu red';
    }
    // Excepciones con mensajes del servidor (ej: onboarding success=false)
    if (e is Exception) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      if (raw.isNotEmpty && raw != 'Exception') return raw;
    }
    return 'Error inesperado. Intentá de nuevo';
  }

  // ─── AuthSessionProvider (para McHttpClient) ───

  @override
  Future<AuthSession?> getSession() async {
    final current = state;
    if (current is AuthSuccess) return current.session;
    return null;
  }

  @override
  Future<AuthSession?> refreshSession() async {
    final current = state;
    if (current is! AuthSuccess) return null;
    try {
      final refreshed =
          await _authPort.refreshToken(current.session.refreshToken);
      emit(AuthSuccess(refreshed));
      return refreshed;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onSessionExpired() async {
    await _authPort.logout();
    emit(const AuthInitial());
  }
}
