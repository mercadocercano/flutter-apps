/// Marca de productos del tenant.
class Brand {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Brand({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  Brand copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
