import 'package:mc_domain/mc_domain.dart';

class CreateMarketplaceAttributeUseCase {
  final MarketplaceAttributeRepository _repository;

  CreateMarketplaceAttributeUseCase(this._repository);

  Future<MarketplaceAttribute> execute(MarketplaceAttribute attr) =>
      _repository.createAttribute(attr);
}
