import 'package:equatable/equatable.dart';

/// Resumen de un template curado del Quickstart, tal como lo devuelve
/// GET /pim/api/v1/quickstart/templates (los 21 templates base por rubro).
///
/// Distinto de [BusinessTypeTemplate] (templates editables por business_type
/// vía /business-type-templates). Este es el catálogo curado read-mostly.
class QuickstartTemplateSummary extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final List<String> categories;
  final List<String> brands;
  final int totalCategories;
  final int totalProducts;
  final bool isActive;

  const QuickstartTemplateSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.icon = '',
    this.categories = const [],
    this.brands = const [],
    this.totalCategories = 0,
    this.totalProducts = 0,
    this.isActive = true,
  });

  factory QuickstartTemplateSummary.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List? ?? const [];
    final rawBrands = json['brands'] as List? ?? const [];

    return QuickstartTemplateSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      categories: rawCategories.whereType<String>().toList(),
      brands: rawBrands
          .map((b) => b is Map ? (b['name'] as String? ?? '') : b.toString())
          .where((s) => s.isNotEmpty)
          .toList(),
      totalCategories: (json['total_categories'] as num?)?.toInt() ?? 0,
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id];
}
