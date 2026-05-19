import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — Mercado Cercano brand manual 2026
/// Source: management/marketing / claude design / colors_and_type.css
class _Tokens {
  // Primary — Cobalto
  static const cobalt = Color(0xFF0A21C0);
  static const cobaltLight = Color(0xFF1a35d4);
  static const cobaltDark = Color(0xFF06178A);
  static const cobalt50 = Color(0xFFEEF0FB);
  static const cobalt100 = Color(0xFFCDD2F4);

  // Accent — Púrpura
  static const purple = Color(0xFF9333EA);
  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFEDE9FE);

  // Navy — ink primario
  static const navy = Color(0xFF050C40);
  static const navyLight = Color(0xFF0C1666);

  // Neutrales (stone/slate)
  static const smoke = Color(0xFFF8FAFC);
  static const gray50 = Color(0xFFF1F5F9);
  static const gray100 = Color(0xFFE2E8F0);
  static const gray200 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);

  // Semánticos
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);

  // Dark mode surfaces
  static const darkBg = Color(0xFF070F2B);
  static const darkSurface = Color(0xFF0F1A3D);
  static const darkSurfaceAlt = Color(0xFF162253);
  static const darkBorder = Color(0xFF1E2D6B);
}

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme({required Color bodyColor}) {
    final poppins = GoogleFonts.poppins;
    final inter = GoogleFonts.inter;
    return TextTheme(
      displayLarge: poppins(fontSize: 57, fontWeight: FontWeight.w700, color: bodyColor),
      displayMedium: poppins(fontSize: 45, fontWeight: FontWeight.w700, color: bodyColor),
      displaySmall: poppins(fontSize: 36, fontWeight: FontWeight.w600, color: bodyColor),
      headlineLarge: poppins(fontSize: 32, fontWeight: FontWeight.w600, color: bodyColor),
      headlineMedium: poppins(fontSize: 28, fontWeight: FontWeight.w600, color: bodyColor),
      headlineSmall: poppins(fontSize: 24, fontWeight: FontWeight.w600, color: bodyColor),
      titleLarge: poppins(fontSize: 20, fontWeight: FontWeight.w600, color: bodyColor),
      titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w500, color: bodyColor),
      titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w500, color: bodyColor),
      bodyLarge: inter(fontSize: 16, fontWeight: FontWeight.w400, color: bodyColor),
      bodyMedium: inter(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall: inter(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor),
      labelLarge: inter(fontSize: 14, fontWeight: FontWeight.w500, color: bodyColor),
      labelMedium: inter(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor),
      labelSmall: inter(fontSize: 11, fontWeight: FontWeight.w500, color: bodyColor),
    );
  }

  static ThemeData light() {
    const primary = _Tokens.cobalt;
    const onPrimary = Colors.white;
    const secondary = _Tokens.purple;
    const background = _Tokens.smoke;
    const surface = Colors.white;
    const onSurface = _Tokens.navy;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: _Tokens.cobalt50,
      onPrimaryContainer: _Tokens.cobaltDark,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: _Tokens.purple100,
      onSecondaryContainer: _Tokens.purple,
      error: _Tokens.error,
      onError: Colors.white,
      errorContainer: _Tokens.errorBg,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: _Tokens.gray600,
      outline: _Tokens.gray100,
      outlineVariant: _Tokens.gray200,
      surfaceContainerHighest: _Tokens.gray50,
      surfaceContainerLow: background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(bodyColor: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _Tokens.navy.withValues(alpha: 0.08),
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _Tokens.gray100),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Tokens.gray100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Tokens.gray100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Tokens.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _Tokens.gray400),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _Tokens.gray600),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _Tokens.gray50,
        selectedColor: _Tokens.cobalt50,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        side: const BorderSide(color: _Tokens.gray100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: _Tokens.gray100,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
        subtitleTextStyle:
            GoogleFonts.inter(fontSize: 12, color: _Tokens.gray500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 4,
        shadowColor: _Tokens.navy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _Tokens.gray100),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, color: onSurface),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    const primary = _Tokens.cobalt;
    const onPrimary = Colors.white;
    const surface = _Tokens.darkSurface;
    const onSurface = Color(0xFFF8FAFC);
    const background = _Tokens.darkBg;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: _Tokens.cobaltDark,
      onPrimaryContainer: _Tokens.cobalt100,
      secondary: _Tokens.purple,
      onSecondary: Colors.white,
      error: _Tokens.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: const Color(0xFFCBD5E1),
      outline: _Tokens.darkBorder,
      outlineVariant: _Tokens.darkBorder,
      surfaceContainerHighest: _Tokens.darkSurfaceAlt,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(bodyColor: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _Tokens.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Tokens.darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Tokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Tokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      dividerTheme: const DividerThemeData(
        color: _Tokens.darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _Tokens.darkSurfaceAlt,
        selectedColor: _Tokens.cobaltDark,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: onSurface),
        side: const BorderSide(color: _Tokens.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _Tokens.darkBorder),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, color: onSurface),
      ),
    );
  }
}
