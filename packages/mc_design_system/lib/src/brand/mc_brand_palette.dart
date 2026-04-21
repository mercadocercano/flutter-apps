import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/mc_colors.dart';

/// Value object inmutable que representa la identidad visual de una marca.
///
/// Se construye desde el DTO del backend (campos hex `#RRGGBB` o `""` cuando
/// el backend devuelve NULL) y aplica un **fallback atómico**: si CUALQUIERA
/// de los dos colores es inválido o vacío, los DOS caen a los tokens neutros
/// de [McColors], y [googleFontFamily] queda en `null`.
///
/// ## Ejemplo de uso
///
/// ```dart
/// final palette = McBrandPalette.fromBrandDto(
///   backgroundHex: '#F40009',
///   textHex: '#FFFFFF',
///   fontFamily: 'Oswald',
///   brightness: Brightness.light,
/// );
///
/// Text(
///   brand.name,
///   style: palette.textStyle(Theme.of(context).textTheme.labelLarge!),
/// );
/// ```
@immutable
class McBrandPalette {
  /// Color de fondo de la marca (siempre no nulo — si el DTO no es válido
  /// se usa el token neutro correspondiente al [brightness] actual).
  final Color backgroundColor;

  /// Color del texto sobre [backgroundColor] (garantiza contraste).
  final Color textColor;

  /// Familia tipográfica de Google Fonts asociada a la marca.
  /// `null` significa que el widget debe heredar la fuente del theme.
  final String? googleFontFamily;

  const McBrandPalette({
    required this.backgroundColor,
    required this.textColor,
    this.googleFontFamily,
  });

  // ─── Factory principal ────────────────────────────────────────────────────

  /// Construye una [McBrandPalette] desde los campos del DTO del backend.
  ///
  /// **Fallback atómico (Q9)**: si CUALQUIERA de [backgroundHex] o [textHex]
  /// es `null`, `""` o un hex inválido, los DOS colores caen a los tokens
  /// neutros de [McColors] según [brightness]. No se lanza ninguna excepción.
  ///
  /// - [backgroundHex]: hex de 6 dígitos con `#` (ej. `"#F40009"`) o `""`.
  /// - [textHex]: hex de 6 dígitos con `#` (ej. `"#FFFFFF"`) o `""`.
  /// - [fontFamily]: nombre de familia de Google Fonts (ej. `"Oswald"`) o `""`.
  /// - [brightness]: determina qué par de tokens neutros usar como fallback.
  factory McBrandPalette.fromBrandDto({
    String? backgroundHex,
    String? textHex,
    String? fontFamily,
    required Brightness brightness,
  }) {
    final parsedBackground = _parseHex(backgroundHex);
    final parsedText = _parseHex(textHex);

    final bool colorsAreValid =
        parsedBackground != null && parsedText != null;

    if (colorsAreValid) {
      return McBrandPalette(
        backgroundColor: parsedBackground,
        textColor: parsedText,
        googleFontFamily: _sanitizeFontFamily(fontFamily),
      );
    }

    return _neutralFallback(brightness);
  }

  // ─── Helpers públicos ─────────────────────────────────────────────────────

  /// Aplica la familia [googleFontFamily] a [base].
  ///
  /// Si [googleFontFamily] es `null` retorna [base] sin modificar.
  /// Si la familia no existe en Google Fonts, captura la excepción
  /// y retorna [base] sin modificar (nunca lanza).
  TextStyle textStyle(TextStyle base) {
    if (googleFontFamily == null) return base;
    try {
      return GoogleFonts.getFont(googleFontFamily!, textStyle: base);
    } catch (_) {
      return base;
    }
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Parsea un string hex `#RRGGBB` a [Color].
  /// Retorna `null` si el string es null, vacío o no tiene formato válido.
  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;

    final trimmed = hex.trim();
    // Acepta exactamente #RRGGBB (7 caracteres, empieza con #).
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(trimmed)) return null;

    final value = int.tryParse(trimmed.substring(1), radix: 16);
    if (value == null) return null;

    return Color(0xFF000000 | value);
  }

  /// Retorna la familia si no es vacía/null; de lo contrario `null`.
  static String? _sanitizeFontFamily(String? family) {
    if (family == null || family.trim().isEmpty) return null;
    return family.trim();
  }

  /// Paleta neutra según el brightness del contexto.
  static McBrandPalette _neutralFallback(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return McBrandPalette(
      backgroundColor:
          isDark ? McColors.mutedDark : McColors.mutedLight,
      textColor:
          isDark ? McColors.foregroundDark : McColors.foregroundLight,
      // Sin familia: hereda del theme.
    );
  }

  // ─── Igualdad y debug ─────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McBrandPalette &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          textColor == other.textColor &&
          googleFontFamily == other.googleFontFamily;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, textColor, googleFontFamily);

  @override
  String toString() => 'McBrandPalette('
      'bg: $backgroundColor, '
      'text: $textColor, '
      'font: $googleFontFamily)';
}
