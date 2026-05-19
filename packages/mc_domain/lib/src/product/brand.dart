/// Marca de productos del tenant.
class Brand {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Brand({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
}
