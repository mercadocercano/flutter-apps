import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio MarketplaceCategory.

/// Parsea lista paginada de categorías.
/// Formato real pim-service:
/// {"categories":[...],"pagination":{"offset":N,"limit":N,"total":N,"total_pages":N,...}}
PaginatedResult<MarketplaceCategory> paginatedCategoriesFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['categories'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
  final total = (pagination['total'] as num?)?.toInt() ?? 0;
  final limit = (pagination['limit'] as num?)?.toInt() ?? 20;
  final offset = (pagination['offset'] as num?)?.toInt() ?? 0;
  final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;
  final page = limit > 0 ? (offset ~/ limit) + 1 : 1;

  return PaginatedResult<MarketplaceCategory>(
    items: rawItems.cast<Map<String, dynamic>>().map(categoryFromJson).toList(),
    totalCount: total,
    page: page,
    pageSize: limit,
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
