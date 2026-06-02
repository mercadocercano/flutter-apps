import 'package:mc_domain/mc_domain.dart';

class GetMarketplaceAttributeUseCase {
  final MarketplaceAttributeRepository _repository;

  GetMarketplaceAttributeUseCase(this._repository);

  Future<MarketplaceAttribute> execute(String id) =>
      _repository.getAttribute(id);
}
