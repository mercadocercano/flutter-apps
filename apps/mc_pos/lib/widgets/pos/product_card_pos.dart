import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../features/quickstart/brand_badge.dart';

/// Formatea un monto como moneda Argentina: $1.234
String fmtAR(double n) {
  final s = n.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '\$$s';
}

/// Card de producto para el grid del POS.
///
/// Orden visual requerido:
/// 1. Imagen/icono (fondo mutedLight)
/// 2. BrandChip con colores de marca
/// 3. Nombre del producto
/// 4. Precio en monospace cobalt
class ProductCardPos extends StatelessWidget {
  final String productName;
  final String? brandName;
  final String? brandBg;
  final String? brandFg;
  final String? brandFont;
  final String? icon;
  final String? imageUrl;
  final String? categoryName;
  final double price;
  final int qtyInCart;
  final bool isKg;
  final int? stock;
  final int? minStock;
  final VoidCallback? onTap;

  const ProductCardPos({
    super.key,
    required this.productName,
    this.brandName,
    this.brandBg,
    this.brandFg,
    this.brandFont,
    this.icon,
    this.imageUrl,
    this.categoryName,
    required this.price,
    this.qtyInCart = 0,
    this.isKg = false,
    this.stock,
    this.minStock,
    this.onTap,
  });

  bool get _isOutOfStock => stock != null && stock! <= 0;
  bool get _isLowStock =>
      !_isOutOfStock && stock != null && minStock != null && stock! <= minStock!;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isOutOfStock ? null : onTap,
      child: Opacity(
        opacity: _isOutOfStock ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: qtyInCart > 0 ? McColors.primary : McColors.borderLight,
              width: qtyInCart > 0 ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(McSpacing.radiusLg),
            boxShadow: qtyInCart > 0
                ? [
                    const BoxShadow(
                      color: McColors.cobaltTint,
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. IMAGEN / ICONO — cuadrada como Fravega (1:1)
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: McColors.mutedLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(McSpacing.radiusLg - 1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Imagen real o fallback a icono cobalt
                      Positioned.fill(
                        child: Opacity(
                          opacity: _isOutOfStock ? 0.4 : 1.0,
                          child: LayoutBuilder(
                            builder: (_, constraints) => ProductImageWidget(
                              imageUrl: imageUrl,
                              category: categoryName,
                              size: constraints.maxWidth,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(McSpacing.radiusLg - 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isKg)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _Badge('x KG', McColors.secondary),
                        ),
                      if (_isOutOfStock)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _Badge('AGOTADO', McColors.error),
                        )
                      else if (_isLowStock)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _Badge('${stock}u', McColors.warning),
                        )
                      else if (qtyInCart > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _QtyBadge(qtyInCart),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. SECCIÓN INFO
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BrandBadge con colores de marca
                    BrandBadge(
                      brandName: brandName ?? '—',
                      size: BrandBadgeSize.sm,
                    ),
                    const SizedBox(height: 4),
                    // Nombre
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: McColors.foregroundLight,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Precio
                    Text(
                      fmtAR(price) + (isKg ? '/kg' : ''),
                      style: McTypography.mono(14, color: McColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badge pequeño ───

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Badge de cantidad en carrito ───

class _QtyBadge extends StatelessWidget {
  final int qty;

  const _QtyBadge(this.qty);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: McColors.primary,
        borderRadius: BorderRadius.circular(McSpacing.radiusFull),
      ),
      alignment: Alignment.center,
      child: Text(
        '$qty',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
