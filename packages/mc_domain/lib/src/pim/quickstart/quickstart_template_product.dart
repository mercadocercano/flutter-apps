import 'package:equatable/equatable.dart';

/// Producto sugerido de un template del Quickstart, tal como lo devuelve
/// GET /pim/api/v1/quickstart/products/:businessType (surtido computado desde
/// global_products, con fallback al editorial).
class QuickstartTemplateProduct extends Equatable {
  final String name;
  final String brand;
  final String categorySlug;
  final String imageUrl;

  const QuickstartTemplateProduct({
    required this.name,
    this.brand = '',
    this.categorySlug = '',
    this.imageUrl = '',
  });

  factory QuickstartTemplateProduct.fromJson(Map<String, dynamic> json) {
    return QuickstartTemplateProduct(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      categorySlug: json['category_slug'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [name, brand, categorySlug, imageUrl];
}
