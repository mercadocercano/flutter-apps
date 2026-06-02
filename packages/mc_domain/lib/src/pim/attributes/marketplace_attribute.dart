import 'package:equatable/equatable.dart';

import 'attribute_type.dart';
import 'attribute_value.dart';

/// Atributo del marketplace — define una propiedad descriptiva de productos
/// globales (color, talla, material, etc.) con sus valores posibles.
class MarketplaceAttribute extends Equatable {
  final String id;
  final String name;
  final String slug;
  final AttributeType type;
  final String? description;
  final bool isRequired;
  final bool isFilterable;
  final List<AttributeValue> values;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketplaceAttribute({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.description,
    this.isRequired = false,
    this.isFilterable = false,
    this.values = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Indica si el atributo admite gestión de valores (select/multiSelect).
  bool get hasValues => type.hasValues;

  MarketplaceAttribute copyWith({
    String? id,
    String? name,
    String? slug,
    AttributeType? type,
    String? description,
    bool? isRequired,
    bool? isFilterable,
    List<AttributeValue>? values,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceAttribute(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isFilterable: isFilterable ?? this.isFilterable,
      values: values ?? this.values,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        type,
        description,
        isRequired,
        isFilterable,
        values,
        createdAt,
        updatedAt,
      ];
}
