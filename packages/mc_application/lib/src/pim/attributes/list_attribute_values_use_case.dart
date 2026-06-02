import 'package:mc_domain/mc_domain.dart';

class ListAttributeValuesUseCase {
  final MarketplaceAttributeRepository _repository;

  ListAttributeValuesUseCase(this._repository);

  Future<List<AttributeValue>> execute(String attributeId) =>
      _repository.listValues(attributeId);
}
