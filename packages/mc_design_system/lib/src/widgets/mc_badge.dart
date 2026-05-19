import 'package:flutter/material.dart';
import '../theme/mc_colors.dart';
import '../theme/mc_spacing.dart';

/// Variantes de badge — mapeadas a los casos de uso del design system.
enum McBadgeVariant {
  /// Stock disponible / venta cobrada.
  success,

  /// Stock bajo / venta pendiente.
  warning,

  /// Sin stock / venta cancelada.
  error,

  /// Cobalt — fiado, rubro almacén, info general.
  cobalt,

  /// Purple — MercadoPago, rubro ferretería, secondary.
  purple,

  /// Gris neutro — sin registrar, sin categoría.
  gray,
}

/// Badge pill del design system de Mercado Cercano.
///
/// Uso:
/// ```dart
/// McBadge(label: 'Stock bajo', variant: McBadgeVariant.warning, dot: true)
/// McBadge(label: 'Cobrado', variant: McBadgeVariant.success)
/// McBadge(label: 'Fiado', variant: McBadgeVariant.cobalt)
/// ```
class McBadge extends StatelessWidget {
  final String label;
  final McBadgeVariant variant;

  /// Muestra un punto de color antes del label (para estados de stock/venta).
  final bool dot;

  const McBadge({
    super.key,
    required this.label,
    this.variant = McBadgeVariant.gray,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors(variant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(McSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colors.fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.fg,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _colors(McBadgeVariant v) => switch (v) {
        McBadgeVariant.success => _BadgeColors(
            bg: McColors.successTint,
            fg: const Color(0xFF15803D),
          ),
        McBadgeVariant.warning => _BadgeColors(
            bg: McColors.warningTint,
            fg: const Color(0xFFB45309),
          ),
        McBadgeVariant.error => _BadgeColors(
            bg: McColors.errorTint,
            fg: const Color(0xFF991B1B),
          ),
        McBadgeVariant.cobalt => _BadgeColors(
            bg: McColors.cobaltTint,
            fg: McColors.primary,
          ),
        McBadgeVariant.purple => _BadgeColors(
            bg: const Color(0xFFFAF5FF),
            fg: McColors.secondaryDark,
          ),
        McBadgeVariant.gray => _BadgeColors(
            bg: const Color(0xFFF1F5F9),
            fg: McColors.textFg2,
          ),
      };
}

class _BadgeColors {
  final Color bg;
  final Color fg;
  const _BadgeColors({required this.bg, required this.fg});
}
