import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía de Mercado Cercano.
/// Fuente: MANUAL_MARCA.md — Poppins (títulos) + Inter (cuerpo).
abstract final class McTypography {
  static TextTheme get textTheme => TextTheme(
        displayLarge: _poppins(57, FontWeight.bold),
        displayMedium: _poppins(45, FontWeight.bold),
        displaySmall: _poppins(36, FontWeight.w600),
        headlineLarge: _poppins(32, FontWeight.w600),
        headlineMedium: _poppins(28, FontWeight.w600),
        headlineSmall: _poppins(24, FontWeight.w600),
        titleLarge: _poppins(22, FontWeight.w600),
        titleMedium: _poppins(16, FontWeight.w500),
        titleSmall: _poppins(14, FontWeight.w500),
        bodyLarge: _inter(16, FontWeight.normal),
        bodyMedium: _inter(14, FontWeight.normal),
        bodySmall: _inter(12, FontWeight.normal),
        labelLarge: _inter(14, FontWeight.w500),
        labelMedium: _inter(12, FontWeight.w500),
        labelSmall: _inter(11, FontWeight.w500),
      );

  static TextStyle _poppins(double size, FontWeight weight) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight);

  static TextStyle _inter(double size, FontWeight weight) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight);
}
