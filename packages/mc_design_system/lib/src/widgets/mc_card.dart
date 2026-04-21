import 'package:flutter/material.dart';
import '../theme/mc_spacing.dart';

/// Card de Mercado Cercano — contenedor visual con bordes redondeados.
class McCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const McCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(McSpacing.base),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(McSpacing.radiusLg),
        child: card,
      );
    }

    return card;
  }
}
