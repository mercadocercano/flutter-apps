import 'package:mc_domain/mc_domain.dart';

class CreateAttributeValueUseCase {
  final MarketplaceAttributeRepository _repository;

  CreateAttributeValueUseCase(this._repository);

  Future<AttributeValue> execute(AttributeValue value) =>
      _repository.createValue(value);
}
