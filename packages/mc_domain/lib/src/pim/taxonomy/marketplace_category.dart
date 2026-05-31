import 'package:equatable/equatable.dart';

/// Categoría del marketplace — administrada globalmente por el admin.
/// Distinta de Category (dominio POS) que es por-tenant.
class MarketplaceCategory extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final int level;
  final bool isActive;
  final int sortOrder;
  final List<MarketplaceCategory> children;
  final List<String> path;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketplaceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.level = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.children = const [],
    this.path = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasChildren => children.isNotEmpty;
  bool get isRoot => parentId == null;

  MarketplaceCategory copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? parentId,
    int? level,
    bool? isActive,
    int? sortOrder,
    List<MarketplaceCategory>? children,
    List<String>? path,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      children: children ?? this.children,
      path: path ?? this.path,
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
        parentId,
        level,
        isActive,
        sortOrder,
        children,
        path,
        createdAt,
        updatedAt,
      ];
}
