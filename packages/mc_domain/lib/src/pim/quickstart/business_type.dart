import 'package:equatable/equatable.dart';

/// Tipo de negocio que define el perfil de un comercio en el proceso de inicio.
///
/// Cada BusinessType agrupa templates que pre-configuran catálogos y categorías
/// para que nuevos comerciantes configuren su tienda rápidamente.
class BusinessType extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final bool isActive;
  final int templateCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessType({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.icon,
    this.isActive = true,
    this.templateCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessType copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? icon,
    bool? isActive,
    int? templateCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessType(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      templateCount: templateCount ?? this.templateCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        icon,
        isActive,
        templateCount,
        createdAt,
        updatedAt,
      ];
}
