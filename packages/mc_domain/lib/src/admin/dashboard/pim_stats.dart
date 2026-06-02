import 'package:equatable/equatable.dart';

/// Value object con las métricas del módulo PIM para el dashboard.
///
/// Agrega contadores de categorías, marcas, productos y atributos del
/// catálogo global, diferenciando entre totales y verificados.
class PimStats extends Equatable {
  final int totalCategories;
  final int verifiedBrands;
  final int totalBrands;
  final int verifiedProducts;
  final int totalProducts;
  final int totalAttributes;

  const PimStats({
    required this.totalCategories,
    required this.verifiedBrands,
    required this.totalBrands,
    required this.verifiedProducts,
    required this.totalProducts,
    required this.totalAttributes,
  });

  /// Porcentaje de marcas verificadas sobre el total (0–100).
  /// Retorna 0 si no hay marcas.
  int get verifiedBrandsPercent {
    if (totalBrands == 0) return 0;
    return ((verifiedBrands / totalBrands) * 100).round();
  }

  /// Porcentaje de productos verificados sobre el total (0–100).
  /// Retorna 0 si no hay productos.
  int get verifiedProductsPercent {
    if (totalProducts == 0) return 0;
    return ((verifiedProducts / totalProducts) * 100).round();
  }

  @override
  List<Object?> get props => [
        totalCategories,
        verifiedBrands,
        totalBrands,
        verifiedProducts,
        totalProducts,
        totalAttributes,
      ];
}
