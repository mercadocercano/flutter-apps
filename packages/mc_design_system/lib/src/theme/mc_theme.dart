import 'package:flutter/material.dart';
import 'mc_colors.dart';
import 'mc_spacing.dart';
import 'mc_typography.dart';

/// ThemeData de Mercado Cercano — light y dark.
abstract final class McTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: McColors.primary,
          secondary: McColors.secondary,
          error: McColors.error,
          surface: McColors.surfaceLight,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: McColors.foregroundLight,
        ),
        scaffoldBackgroundColor: McColors.backgroundLight,
        textTheme: McTypography.textTheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusMd),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: McSpacing.base,
            vertical: McSpacing.md,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, McSpacing.touchTargetMin),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(McSpacing.radiusLg),
            ),
            textStyle: McTypography.textTheme.labelLarge,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          ),
          elevation: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: McColors.backgroundLight,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: McColors.primary, width: 2),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: McColors.primaryLight,
          secondary: McColors.secondaryLight,
          error: McColors.error,
          surface: McColors.surfaceDark,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: McColors.foregroundDark,
        ),
        scaffoldBackgroundColor: McColors.backgroundDark,
        textTheme: McTypography.textTheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusMd),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: McSpacing.base,
            vertical: McSpacing.md,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, McSpacing.touchTargetMin),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(McSpacing.radiusLg),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
          ),
          elevation: 2,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: McColors.surfaceDark,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: McColors.primaryLight, width: 2),
          ),
        ),
      );
}
