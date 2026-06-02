import 'package:mc_domain/mc_domain.dart';

class DeleteAttributeValueUseCase {
  final MarketplaceAttributeRepository _repository;

  DeleteAttributeValueUseCase(this._repository);

  Future<void> execute(String attributeId, String valueId) =>
      _repository.deleteValue(attributeId, valueId);
}
