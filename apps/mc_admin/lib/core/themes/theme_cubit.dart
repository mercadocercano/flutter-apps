import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el ThemeMode de mc_admin y lo persiste entre sesiones.
/// El estado vive arriba del MaterialApp; el toggle se dispara desde el shell.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_decode(_prefs.getString(_key)));

  static const _key = 'mc_admin_theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  /// Alterna claro <-> oscuro y persiste la elección.
  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void set(ThemeMode mode) {
    if (mode == state) return;
    emit(mode);
    _prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
