import 'package:flutter/material.dart';
import 'package:mc_design_system/mc_design_system.dart';

/// Badge visual de marca con colores y tipografía real.
/// Cada marca conocida tiene su paleta propia.
/// Tamaños de badge.
enum BrandBadgeSize {
  sm(28, 11, 6),
  md(40, 13, 8),
  lg(48, 14, 10);

  final double height;
  final double baseFontSize;
  final double horizontalPadding;
  const BrandBadgeSize(this.height, this.baseFontSize, this.horizontalPadding);
}

class BrandBadge extends StatelessWidget {
  final String brandName;
  final BrandBadgeSize size;
  final double? width;
  final double? height;
  final String? brandColor;

  const BrandBadge({
    super.key,
    required this.brandName,
    this.size = BrandBadgeSize.md,
    this.width,
    this.height,
    this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = _brandStyles[brandName.toLowerCase()] ?? _defaultStyle(brandName);
    final h = height ?? size.height;
    final fontSize = (style.fontSize / 13) * size.baseFontSize;

    final customBgColor = _parseHexColor(brandColor);
    final effectiveBgColor = customBgColor ?? style.bgColor;
    final effectiveTextColor = customBgColor != null ? Colors.white : style.textColor;

    final container = Container(
      height: h,
      constraints: width != null ? BoxConstraints(minWidth: width!) : null,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(McSpacing.radiusSm),
        border: customBgColor == null && style.borderColor != null
            ? Border.all(color: style.borderColor!, width: 0.5)
            : null,
        gradient: customBgColor == null ? style.gradient : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
      child: Center(
        child: Text(
          style.displayName,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: fontSize,
            fontWeight: style.fontWeight,
            fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
            letterSpacing: style.letterSpacing,
            fontFamily: style.fontFamily,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );

    return width != null ? container : IntrinsicWidth(child: container);
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    final value = int.tryParse('FF$h', radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

/// Badge chico para lista de productos.
class BrandBadgeSmall extends StatelessWidget {
  final String brandName;

  const BrandBadgeSmall({super.key, required this.brandName});

  @override
  Widget build(BuildContext context) {
    return BrandBadge(brandName: brandName, size: BrandBadgeSize.sm);
  }
}

class _BrandStyle {
  final String displayName;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isItalic;
  final double letterSpacing;
  final String? fontFamily;
  final Gradient? gradient;

  const _BrandStyle({
    required this.displayName,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.fontSize = 13,
    this.fontWeight = FontWeight.bold,
    this.isItalic = false,
    this.letterSpacing = 0,
    this.fontFamily,
    this.gradient,
  });
}

_BrandStyle _defaultStyle(String name) => _BrandStyle(
      displayName: name,
      bgColor: const Color(0xFFF1F5F9),
      textColor: const Color(0xFF334155),
      borderColor: const Color(0xFFCBD5E1),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

final _brandStyles = <String, _BrandStyle>{
  // ─── Bebidas ───
  'coca-cola': const _BrandStyle(
    displayName: 'Coca-Cola',
    bgColor: Color(0xFFE61A27),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    isItalic: true,
    letterSpacing: -0.5,
  ),
  'sprite': const _BrandStyle(
    displayName: 'Sprite',
    bgColor: Color(0xFF008B47),
    textColor: Color(0xFFFFD700),
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  ),
  'pepsi': const _BrandStyle(
    displayName: 'PEPSI',
    bgColor: Color(0xFF004B93),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'fanta': const _BrandStyle(
    displayName: 'Fanta',
    bgColor: Color(0xFFF57C20),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  ),
  'quilmes': const _BrandStyle(
    displayName: 'QUILMES',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
  ),
  'brahma': const _BrandStyle(
    displayName: 'BRAHMA',
    bgColor: Color(0xFFCC0000),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'stella artois': const _BrandStyle(
    displayName: 'Stella Artois',
    bgColor: Color(0xFF1D4731),
    textColor: Color(0xFFD4AF37),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  'fernet branca': const _BrandStyle(
    displayName: 'FERNET',
    bgColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFD4AF37),
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'branca': const _BrandStyle(
    displayName: 'BRANCA',
    bgColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFD4AF37),
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'red bull': const _BrandStyle(
    displayName: 'Red Bull',
    bgColor: Color(0xFF1E3264),
    textColor: Color(0xFFFFCC00),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),
  'speed': const _BrandStyle(
    displayName: 'SPEED',
    bgColor: Color(0xFF000000),
    textColor: Color(0xFF00FF00),
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'villavicencio': const _BrandStyle(
    displayName: 'Villavicencio',
    bgColor: Color(0xFF0077B6),
    textColor: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  ),

  // ─── Lácteos ───
  'la serenísima': const _BrandStyle(
    displayName: 'La Serenísima',
    bgColor: Color(0xFF006B3C),
    textColor: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w800,
  ),
  'sancor': const _BrandStyle(
    displayName: 'SanCor',
    bgColor: Color(0xFF003893),
    textColor: Color(0xFFFFCC00),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),

  // ─── Almacén ───
  'arcor': const _BrandStyle(
    displayName: 'arcor',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  ),
  'marolio': const _BrandStyle(
    displayName: 'Marolio',
    bgColor: Color(0xFFFFCC00),
    textColor: Color(0xFFCC0000),
    fontSize: 13,
    fontWeight: FontWeight.w900,
  ),
  'molinos': const _BrandStyle(
    displayName: 'MOLINOS',
    bgColor: Color(0xFF003399),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  ),
  'taragüi': const _BrandStyle(
    displayName: 'Taragüi',
    bgColor: Color(0xFF006633),
    textColor: Color(0xFFFFCC00),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),
  'playadito': const _BrandStyle(
    displayName: 'Playadito',
    bgColor: Color(0xFF2E7D32),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
  'ledesma': const _BrandStyle(
    displayName: 'LEDESMA',
    bgColor: Color(0xFF006837),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'la campagnola': const _BrandStyle(
    displayName: 'La Campagnola',
    bgColor: Color(0xFF8B0000),
    textColor: Color(0xFFFFD700),
    fontSize: 10,
    fontWeight: FontWeight.w700,
  ),

  // ─── Galletitas y Golosinas ───
  'bagley': const _BrandStyle(
    displayName: 'Bagley',
    bgColor: Color(0xFF1B365D),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  'oreo': const _BrandStyle(
    displayName: 'OREO',
    bgColor: Color(0xFF1A1F71),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'milka': const _BrandStyle(
    displayName: 'Milka',
    bgColor: Color(0xFF7B2D8E),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    isItalic: true,
  ),
  'havanna': const _BrandStyle(
    displayName: 'HAVANNA',
    bgColor: Color(0xFF4A2C2A),
    textColor: Color(0xFFD4AF37),
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
  ),
  'guaymallén': const _BrandStyle(
    displayName: 'Guaymallén',
    bgColor: Color(0xFFFF6600),
    textColor: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w800,
  ),

  // ─── Snacks ───
  'lays': const _BrandStyle(
    displayName: "Lay's",
    bgColor: Color(0xFFFFCC00),
    textColor: Color(0xFFD42A2A),
    fontSize: 14,
    fontWeight: FontWeight.w900,
    isItalic: true,
  ),
  'cheetos': const _BrandStyle(
    displayName: 'CHEETOS',
    bgColor: Color(0xFFF57C20),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  ),

  // ─── Limpieza ───
  'skip': const _BrandStyle(
    displayName: 'Skip',
    bgColor: Color(0xFF00529B),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  ),
  'magistral': const _BrandStyle(
    displayName: 'Magistral',
    bgColor: Color(0xFF006B3C),
    textColor: Color(0xFFFFCC00),
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
  'ayudín': const _BrandStyle(
    displayName: 'Ayudín',
    bgColor: Color(0xFF0077B6),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),

  // ─── Fiambres ───
  'paladini': const _BrandStyle(
    displayName: 'PALADINI',
    bgColor: Color(0xFFCC0000),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'vienissima': const _BrandStyle(
    displayName: 'Vienissima',
    bgColor: Color(0xFFE30613),
    textColor: Color(0xFFFFCC00),
    fontSize: 11,
    fontWeight: FontWeight.w700,
  ),

  // ─── Harinas ───
  'pureza': const _BrandStyle(
    displayName: 'Pureza',
    bgColor: Color(0xFF0054A6),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  'blancaflor': const _BrandStyle(
    displayName: 'Blancaflor',
    bgColor: Color(0xFF2196F3),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
  'presto pronta': const _BrandStyle(
    displayName: 'Presto Pronta',
    bgColor: Color(0xFFFFCC00),
    textColor: Color(0xFF333333),
    fontSize: 10,
    fontWeight: FontWeight.w800,
  ),
  'cabrales': const _BrandStyle(
    displayName: 'CABRALES',
    bgColor: Color(0xFF4A2C2A),
    textColor: Color(0xFFD4AF37),
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'dos anclas': const _BrandStyle(
    displayName: 'Dos Anclas',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  ),

  // ─── Perfumería ───
  'dove': const _BrandStyle(
    displayName: 'Dove',
    bgColor: Color(0xFF003DA5),
    textColor: Color(0xFFD4AF37),
    fontSize: 14,
    fontWeight: FontWeight.w700,
    isItalic: true,
  ),
  'pantene': const _BrandStyle(
    displayName: 'PANTENE',
    bgColor: Color(0xFF002B5C),
    textColor: Color(0xFFD4AF37),
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'rexona': const _BrandStyle(
    displayName: 'REXONA',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  ),
  'nivea': const _BrandStyle(
    displayName: 'NIVEA',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'sedal': const _BrandStyle(
    displayName: 'Sedal',
    bgColor: Color(0xFF7B2D8E),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  'colgate': const _BrandStyle(
    displayName: 'Colgate',
    bgColor: Color(0xFFCC0000),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),

  // ─── Ferretería ───
  'stanley': const _BrandStyle(
    displayName: 'STANLEY',
    bgColor: Color(0xFFFFCC00),
    textColor: Color(0xFF000000),
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
  'tramontina': const _BrandStyle(
    displayName: 'TRAMONTINA',
    bgColor: Color(0xFFCC0000),
    textColor: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'alba': const _BrandStyle(
    displayName: 'ALBA',
    bgColor: Color(0xFF003DA5),
    textColor: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 3,
  ),
  'loma negra': const _BrandStyle(
    displayName: 'Loma Negra',
    bgColor: Color(0xFF333333),
    textColor: Color(0xFFFFCC00),
    fontSize: 11,
    fontWeight: FontWeight.w800,
  ),
  'acindar': const _BrandStyle(
    displayName: 'ACINDAR',
    bgColor: Color(0xFF003366),
    textColor: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  'bahco': const _BrandStyle(
    displayName: 'BAHCO',
    bgColor: Color(0xFF006B3C),
    textColor: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  ),
};
