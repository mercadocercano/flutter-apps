import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_design_system/mc_design_system.dart';

void main() {
  group('McBrandPalette', () {
    // ─── Builder helpers (Object Mother) ─────────────────────────────────────

    McBrandPalette buildFromDto({
      String? backgroundHex = '#F40009',
      String? textHex = '#FFFFFF',
      String? fontFamily,
      Brightness brightness = Brightness.light,
    }) {
      return McBrandPalette.fromBrandDto(
        backgroundHex: backgroundHex,
        textHex: textHex,
        fontFamily: fontFamily,
        brightness: brightness,
      );
    }

    // ─── T031-1: hex válido → parsea correctamente ────────────────────────

    test('TestMcBrandPalette_WithValidDto_ParsesHexAndFont', () {
      // Arrange — hex de Coca-Cola + fuente conocida de Google Fonts
      const expectedBg = Color(0xFFF40009);
      const expectedText = Color(0xFFFFFFFF);

      // Act
      final palette = buildFromDto(
        backgroundHex: '#F40009',
        textHex: '#FFFFFF',
        fontFamily: 'Oswald',
      );

      // Assert
      expect(palette.backgroundColor, equals(expectedBg),
          reason: 'Background color debe ser #F40009');
      expect(palette.textColor, equals(expectedText),
          reason: 'Text color debe ser #FFFFFF');
      expect(palette.googleFontFamily, equals('Oswald'),
          reason: 'Font family debe preservarse cuando es válida');
    });

    // ─── T031-2: backgroundHex null → ambos colores neutros ──────────────

    test('TestMcBrandPalette_WithNullBackground_FallsBackAtomically', () {
      // Arrange — backgroundHex null, textHex válido
      // Act
      final palette = buildFromDto(
        backgroundHex: null,
        textHex: '#FFFFFF',
        brightness: Brightness.light,
      );

      // Assert — fallback atómico: los DOS caen a neutros, no sólo uno
      expect(palette.backgroundColor, equals(McColors.mutedLight),
          reason: 'Background debe ser mutedLight cuando backgroundHex es null');
      expect(palette.textColor, equals(McColors.foregroundLight),
          reason: 'Text debe ser foregroundLight aunque textHex fuera válido');
      expect(palette.googleFontFamily, isNull,
          reason: 'Font debe ser null en fallback atómico');
    });

    // ─── T031-3: textHex null → ambos colores neutros ────────────────────

    test('TestMcBrandPalette_WithNullTextColor_FallsBackAtomically', () {
      // Arrange — backgroundHex válido, textHex null
      // Act
      final palette = buildFromDto(
        backgroundHex: '#F40009',
        textHex: null,
        brightness: Brightness.light,
      );

      // Assert — fallback atómico activa aunque sólo uno sea inválido
      expect(palette.backgroundColor, equals(McColors.mutedLight),
          reason: 'Background debe ser mutedLight aunque backgroundHex fuera válido');
      expect(palette.textColor, equals(McColors.foregroundLight),
          reason: 'Text debe ser foregroundLight cuando textHex es null');
      expect(palette.googleFontFamily, isNull,
          reason: 'Font debe ser null en fallback atómico');
    });

    // ─── T031-4: strings vacíos equivalen a null ─────────────────────────

    test('TestMcBrandPalette_WithEmptyStrings_FallsBackAtomically', () {
      // Arrange — strings vacíos como los devuelve el backend cuando DB es NULL
      // Act
      final palette = buildFromDto(
        backgroundHex: '',
        textHex: '',
        fontFamily: '',
        brightness: Brightness.light,
      );

      // Assert
      expect(palette.backgroundColor, equals(McColors.mutedLight),
          reason: 'String vacío debe tratarse igual que null');
      expect(palette.textColor, equals(McColors.foregroundLight),
          reason: 'String vacío debe tratarse igual que null');
      expect(palette.googleFontFamily, isNull,
          reason: 'Font family vacío debe quedar null');
    });

    // ─── T031-5: hex inválido → fallback gracioso, sin excepción ─────────

    test('TestMcBrandPalette_WithInvalidHex_FallsBackGracefully', () {
      // Arrange — varios formatos inválidos
      final invalidCases = [
        '#ZZZ',
        'red',
        '#FFF',    // 3 dígitos, no 6
        'F40009',  // sin #
        '#F4000G', // caracter no hex
        '##F40009',
      ];

      for (final invalidHex in invalidCases) {
        // Act + Assert — no debe lanzar excepción
        expect(
          () => buildFromDto(backgroundHex: invalidHex, textHex: '#FFFFFF'),
          returnsNormally,
          reason: '"$invalidHex" no debe lanzar excepción',
        );

        final palette =
            buildFromDto(backgroundHex: invalidHex, textHex: '#FFFFFF');
        expect(palette.backgroundColor, equals(McColors.mutedLight),
            reason: '"$invalidHex" debe producir fallback neutro');
      }
    });

    // ─── T031-6: dark mode usa tokens oscuros ────────────────────────────

    test('TestMcBrandPalette_WithDarkBrightness_UsesDarkFallback', () {
      // Arrange — backgroundHex null fuerza fallback en dark mode
      // Act
      final palette = buildFromDto(
        backgroundHex: null,
        textHex: null,
        brightness: Brightness.dark,
      );

      // Assert — tokens de dark, no de light
      expect(palette.backgroundColor, equals(McColors.mutedDark),
          reason: 'Dark fallback debe usar mutedDark');
      expect(palette.textColor, equals(McColors.foregroundDark),
          reason: 'Dark fallback debe usar foregroundDark');
    });

    // ─── T031-7: familia inexistente → retorna base TextStyle, sin throw ─

    test('TestMcBrandPalette_WithUnknownGoogleFont_FallsBackToBaseStyle', () {
      // Arrange — familia inventada que Google Fonts no conoce
      const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

      final palette = McBrandPalette(
        backgroundColor: McColors.mutedLight,
        textColor: McColors.foregroundLight,
        googleFontFamily: 'FamiliaQueNoExisteEnAbsoluto99999',
      );

      // Act + Assert — no debe lanzar excepción
      expect(() => palette.textStyle(baseStyle), returnsNormally,
          reason: 'Familia inexistente no debe lanzar excepción');

      final result = palette.textStyle(baseStyle);
      // El resultado puede ser igual a base o una variante; lo importante es
      // que sea un TextStyle válido con el fontSize original.
      expect(result.fontSize, equals(baseStyle.fontSize),
          reason: 'El fontSize base debe preservarse ante familia inexistente');
    });

    // ─── Comportamiento de textStyle con familia null ─────────────────────

    test('TestMcBrandPalette_WithNullFont_ReturnsBaseStyleUnmodified', () {
      // Arrange
      const baseStyle = TextStyle(fontSize: 16);
      final palette = McBrandPalette(
        backgroundColor: McColors.mutedLight,
        textColor: McColors.foregroundLight,
      );

      // Act
      final result = palette.textStyle(baseStyle);

      // Assert — sin familia, el style no cambia
      expect(result, equals(baseStyle),
          reason: 'Sin googleFontFamily, textStyle debe retornar base sin cambios');
    });

    // ─── Inmutabilidad y value semantics ────────────────────────────────

    test('TestMcBrandPalette_EqualityByValue', () {
      // Arrange
      final a = buildFromDto(backgroundHex: '#0A21C0', textHex: '#FFFFFF');
      final b = buildFromDto(backgroundHex: '#0A21C0', textHex: '#FFFFFF');

      // Assert — value object: dos instancias con los mismos datos son iguales
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
