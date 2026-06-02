import 'package:mc_domain/mc_domain.dart';

class UpdateMarketplaceAttributeUseCase {
  final MarketplaceAttributeRepository _repository;

  UpdateMarketplaceAttributeUseCase(this._repository);

  Future<MarketplaceAttribute> execute(MarketplaceAttribute attr) =>
      _repository.updateAttribute(attr);
}
