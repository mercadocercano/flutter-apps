import 'package:flutter/material.dart';
import '../theme/mc_colors.dart';
import '../theme/mc_spacing.dart';

/// Variantes de botón MC.
enum McButtonVariant { primary, secondary, outline, ghost, destructive }

/// Tamaños de botón MC.
enum McButtonSize { sm, md, lg }

/// Botón de Mercado Cercano — touch target mínimo 48dp para POS.
class McButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final McButtonVariant variant;
  final McButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const McButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = McButtonVariant.primary,
    this.size = McButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      McButtonSize.sm => 40.0,
      McButtonSize.md => McSpacing.touchTargetMin,
      McButtonSize.lg => McSpacing.touchTargetIdeal,
    };

    final padding = switch (size) {
      McButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      McButtonSize.md => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      McButtonSize.lg => const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    };

    final style = _buildStyle(context, height, padding);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(context),
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      McButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      McButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      _ => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  ButtonStyle _buildStyle(BuildContext context, double height, EdgeInsets padding) {
    final bg = switch (variant) {
      McButtonVariant.primary => McColors.primary,
      McButtonVariant.secondary => McColors.secondary,
      McButtonVariant.destructive => McColors.error,
      McButtonVariant.outline => Colors.transparent,
      McButtonVariant.ghost => Colors.transparent,
    };

    final fg = _foregroundColor(context);

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: Size(0, height),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        side: variant == McButtonVariant.outline
            ? BorderSide(color: Theme.of(context).colorScheme.outline)
            : BorderSide.none,
      ),
      elevation: variant == McButtonVariant.outline || variant == McButtonVariant.ghost ? 0 : 1,
    );
  }

  Color _foregroundColor(BuildContext context) => switch (variant) {
        McButtonVariant.primary ||
        McButtonVariant.secondary ||
        McButtonVariant.destructive =>
          Colors.white,
        McButtonVariant.outline ||
        McButtonVariant.ghost =>
          Theme.of(context).colorScheme.onSurface,
      };
}
