import 'package:flutter/material.dart';

import '../theme/mc_spacing.dart';
import 'mc_brand_palette.dart';

/// Chip que muestra el nombre de una marca con su identidad visual.
///
/// Aplica [palette.backgroundColor] como fondo, [palette.textColor] como
/// color del texto, y [palette.textStyle] para la tipografía de marca.
/// Responde automáticamente al [brightness] del theme: si la paleta fue
/// construida con [McBrandPalette.fromBrandDto] usando el brightness actual,
/// el fallback neutro ya estará en el rango correcto.
///
/// ## Ejemplo de uso
///
/// ```dart
/// McBrandChip(
///   brandName: 'Coca-Cola',
///   palette: McBrandPalette.fromBrandDto(
///     backgroundHex: '#F40009',
///     textHex: '#FFFFFF',
///     fontFamily: 'Oswald',
///     brightness: Theme.of(context).brightness,
///   ),
/// )
/// ```
class McBrandChip extends StatelessWidget {
  /// Nombre de la marca que se muestra en el chip.
  final String brandName;

  /// Paleta de identidad visual de la marca.
  final McBrandPalette palette;

  const McBrandChip({
    super.key,
    required this.brandName,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);

    final labelStyle = palette.textStyle(baseStyle).copyWith(
          color: palette.textColor,
        );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: McSpacing.sm,
        vertical: McSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(McSpacing.radiusSm),
      ),
      child: Text(
        brandName,
        style: labelStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
