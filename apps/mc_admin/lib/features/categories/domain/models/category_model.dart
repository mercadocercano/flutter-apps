/// Category domain model
class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final int level;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.level = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      level: json['level'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'parent_id': parentId,
      'level': level,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  static Category empty() {
    return const Category(
      id: '',
      name: '',
      slug: '',
    );
  }
}