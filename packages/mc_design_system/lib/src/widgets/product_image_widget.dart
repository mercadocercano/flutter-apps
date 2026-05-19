import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_spacing.dart';
import 'product_category_icon.dart';

/// Widget de imagen de producto con fallback a icono vectorial.
///
/// - Si [imageUrl] no es null/vacío → muestra la foto con [CachedNetworkImage],
///   shimmer de carga y fallback al icono ante error de red.
/// - Si [imageUrl] es null/vacío → muestra un icono de Material derivado de
///   [category] o [businessType], en color cobalt sobre fondo cobaltTint.
///
/// Ejemplos:
/// ```dart
/// // Con imagen real
/// ProductImageWidget(
///   imageUrl: product.imageUrl,
///   category: product.category,
///   size: 80,
/// )
///
/// // Solo fallback (producto sin imagen)
/// ProductImageWidget(
///   imageUrl: null,
///   category: 'Lácteos',
///   businessType: 'almacen',
/// )
/// ```
class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;

  /// Categoría del producto en español (ej: "Lácteos", "Bebidas").
  final String? category;

  /// Tipo de negocio (ej: "almacen", "ferreteria"). Se usa como fallback
  /// si [category] no tiene match en el mapeo.
  final String? businessType;

  /// Tamaño del widget (ancho y alto iguales). Default: 64.
  final double size;

  /// Radio de esquinas. Si es null usa [BorderRadius.circular(8)].
  final BorderRadius? borderRadius;

  /// Padding interno para la imagen real. Default: 8.
  final double imagePadding;

  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    this.category,
    this.businessType,
    this.size = 64,
    this.borderRadius,
    this.imagePadding = 8,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  BorderRadius get _resolvedRadius =>
      borderRadius ?? BorderRadius.circular(McSpacing.radiusSm);

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return _ImageView(
        imageUrl: imageUrl!,
        size: size,
        borderRadius: _resolvedRadius,
        imagePadding: imagePadding,
        fallbackIcon: _resolvedIcon,
      );
    }
    return _IconFallback(
      icon: _resolvedIcon,
      size: size,
      borderRadius: _resolvedRadius,
    );
  }

  IconData get _resolvedIcon => ProductCategoryIcon.iconFor(
        category: category,
        businessType: businessType,
      );
}

// ─── Vista con imagen real ────────────────────────────────────────────────────

class _ImageView extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius borderRadius;
  final double imagePadding;
  final IconData fallbackIcon;

  const _ImageView({
    required this.imageUrl,
    required this.size,
    required this.borderRadius,
    required this.imagePadding,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          memCacheWidth: (size * 2).toInt(),
          placeholder: (_, __) => _Shimmer(size: size),
          errorWidget: (_, __, ___) => _IconFallback(
            icon: fallbackIcon,
            size: size,
            borderRadius: BorderRadius.zero,
          ),
          imageBuilder: (_, imageProvider) => Padding(
            padding: EdgeInsets.all(imagePadding),
            child: Image(image: imageProvider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ─── Fallback con icono cobalt ─────────────────────────────────────────────────

class _IconFallback extends StatelessWidget {
  final IconData icon;
  final double size;
  final BorderRadius borderRadius;

  const _IconFallback({
    required this.icon,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: McColors.cobaltTint,
        borderRadius: borderRadius,
      ),
      child: Icon(
        icon,
        color: McColors.primary,
        size: size * 0.45,
      ),
    );
  }
}

// ─── Shimmer de carga ──────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double size;

  const _Shimmer({required this.size});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        color: McColors.mutedLight.withValues(alpha: _anim.value),
      ),
    );
  }
}
