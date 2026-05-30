/// Parámetros para crear una marca en el marketplace.
class CreateBrandParams {
  final String name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? backgroundColor;
  final String? textColor;
  final String? typography;

  const CreateBrandParams({
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.backgroundColor,
    this.textColor,
    this.typography,
  });
}

/// Parámetros para actualizar una marca existente.
class UpdateBrandParams {
  final String? name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final String? backgroundColor;
  final String? textColor;
  final String? typography;

  const UpdateBrandParams({
    this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.backgroundColor,
    this.textColor,
    this.typography,
  });
}
