/// Business types domain model
class BusinessType {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final bool isActive;
  final int sortOrder;

  const BusinessType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory BusinessType.fromJson(Map<String, dynamic> json) {
    return BusinessType(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}