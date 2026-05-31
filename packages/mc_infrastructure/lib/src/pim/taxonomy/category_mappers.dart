import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio MarketplaceCategory.

/// Parsea lista paginada de categorías.
/// Formato: {"categories":[...],"total":N,"page":N,"page_size":N,"total_pages":N}
PaginatedResult<MarketplaceCategory> paginatedCategoriesFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['categories'] as List?) ?? [];
  final total = (json['total'] as num?)?.toInt() ?? 0;
  final page = (json['page'] as num?)?.toInt() ?? 1;
  final pageSize = (json['page_size'] as num?)?.toInt() ?? 20;
  final totalPages = (json['total_pages'] as num?)?.toInt() ?? 1;

  return PaginatedResult<MarketplaceCategory>(
    items: rawItems.cast<Map<String, dynamic>>().map(categoryFromJson).toList(),
    totalCount: total,
    page: page,
    pageSize: pageSize,
    totalPages: totalPages,
  );
}

/// Parsea el árbol de categorías.
/// Formato: {"categories":[...nodos con "children" anidados...]}
CategoryTree treeFromJson(Map<String, dynamic> json) {
  final rawItems = (json['categories'] as List?) ?? [];
  final roots = rawItems
      .cast<Map<String, dynamic>>()
      .map(categoryFromJson)
      .toList();
  return CategoryTree(roots: roots);
}

/// Parsea un nodo de categoría (recursivo para children).
MarketplaceCategory categoryFromJson(Map<String, dynamic> json) {
  final rawChildren = (json['children'] as List?) ?? [];
  final children = rawChildren
      .cast<Map<String, dynamic>>()
      .map(categoryFromJson)
      .toList();

  return MarketplaceCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: (json['slug'] as String?) ?? '',
    description: json['description'] as String?,
    parentId: json['parent_id'] as String?,
    level: (json['level'] as num?)?.toInt() ?? 0,
    isActive: (json['is_active'] as bool?) ?? true,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    children: children,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
