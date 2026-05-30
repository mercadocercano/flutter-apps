import 'package:mc_domain/mc_domain.dart';

class GetBrandUseCase {
  final MarketplaceBrandRepository _repository;

  GetBrandUseCase(this._repository);

  Future<MarketplaceBrand> execute(String id) => _repository.getById(id);
}
