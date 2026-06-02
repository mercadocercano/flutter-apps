import 'package:equatable/equatable.dart';

/// Producto del catálogo global — administrado por el admin del marketplace.
/// Distinto de Product (dominio POS) que es por-tenant.
class GlobalProduct extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final String? imageUrl;
  final List<String> businessTypeIds;
  final String? categoryId;
  final Map<String, dynamic> attributes;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GlobalProduct({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.description,
    this.imageUrl,
    this.businessTypeIds = const [],
    this.categoryId,
    this.attributes = const {},
    this.isVerified = false,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  GlobalProduct copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    String? imageUrl,
    List<String>? businessTypeIds,
    String? categoryId,
    Map<String, dynamic>? attributes,
    bool? isVerified,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      businessTypeIds: businessTypeIds ?? this.businessTypeIds,
      categoryId: categoryId ?? this.categoryId,
      attributes: attributes ?? this.attributes,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        barcode,
        description,
        imageUrl,
        businessTypeIds,
        categoryId,
        attributes,
        isVerified,
        verifiedAt,
        createdAt,
        updatedAt,
      ];
}
