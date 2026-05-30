import 'package:mc_domain/mc_domain.dart';

class ValidateBrandNameUseCase {
  final MarketplaceBrandRepository _repository;

  ValidateBrandNameUseCase(this._repository);

  /// Returns true si el nombre está disponible, false si ya existe.
  /// [excludeId]: id de la marca actual al editar, para ignorarla en la búsqueda.
  Future<bool> execute(String name, {String? excludeId}) async {
    if (name.trim().isEmpty) return true;
    final result = await _repository.getAll(1, 5, name: name.trim());
    return !result.items.any(
      (b) =>
          b.name.toLowerCase() == name.trim().toLowerCase() &&
          b.id != excludeId,
    );
  }
}
