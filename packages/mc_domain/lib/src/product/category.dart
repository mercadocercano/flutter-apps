/// Categoría de productos del tenant.
class Category {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRoot => parentId == null;
}
