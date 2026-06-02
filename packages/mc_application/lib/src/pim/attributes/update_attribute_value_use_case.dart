import 'package:mc_domain/mc_domain.dart';

class UpdateAttributeValueUseCase {
  final MarketplaceAttributeRepository _repository;

  UpdateAttributeValueUseCase(this._repository);

  Future<AttributeValue> execute(AttributeValue value) =>
      _repository.updateValue(value);
}
