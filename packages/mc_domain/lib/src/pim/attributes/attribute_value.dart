import 'package:equatable/equatable.dart';

/// Valor posible de un atributo de tipo select o multi-select.
class AttributeValue extends Equatable {
  final String id;
  final String attributeId;
  final String value;
  final String label;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttributeValue({
    required this.id,
    required this.attributeId,
    required this.value,
    required this.label,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  AttributeValue copyWith({
    String? id,
    String? attributeId,
    String? value,
    String? label,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttributeValue(
      id: id ?? this.id,
      attributeId: attributeId ?? this.attributeId,
      value: value ?? this.value,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attributeId,
        value,
        label,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
