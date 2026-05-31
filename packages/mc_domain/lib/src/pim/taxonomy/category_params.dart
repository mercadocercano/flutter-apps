/// Parámetros para crear una categoría del marketplace.
class CreateCategoryParams {
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;

  const CreateCategoryParams({
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });
}

/// Parámetros para actualizar una categoría existente.
class UpdateCategoryParams {
  final String? name;
  final String? slug;
  final String? description;
  final String? parentId;
  final bool? isActive;
  final int? sortOrder;

  const UpdateCategoryParams({
    this.name,
    this.slug,
    this.description,
    this.parentId,
    this.isActive,
    this.sortOrder,
  });
}
