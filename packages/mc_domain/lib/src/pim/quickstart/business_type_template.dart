import 'package:equatable/equatable.dart';

/// Template de configuración inicial asociado a un BusinessType.
///
/// Define un conjunto de categorías y productos base que se aplican al
/// catálogo de un comercio cuando elige su tipo de negocio durante el inicio.
class BusinessTypeTemplate extends Equatable {
  final String id;
  final String businessTypeId;
  final String name;
  final String? description;
  final List<String> categoryIds;
  final List<String> baseProductIds;
  final bool isDuplicate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessTypeTemplate({
    required this.id,
    required this.businessTypeId,
    required this.name,
    this.description,
    this.categoryIds = const [],
    this.baseProductIds = const [],
    this.isDuplicate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessTypeTemplate copyWith({
    String? id,
    String? businessTypeId,
    String? name,
    String? description,
    List<String>? categoryIds,
    List<String>? baseProductIds,
    bool? isDuplicate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessTypeTemplate(
      id: id ?? this.id,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryIds: categoryIds ?? this.categoryIds,
      baseProductIds: baseProductIds ?? this.baseProductIds,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessTypeId,
        name,
        description,
        categoryIds,
        baseProductIds,
        isDuplicate,
        createdAt,
        updatedAt,
      ];
}
