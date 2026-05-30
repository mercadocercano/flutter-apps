import 'package:mc_domain/mc_domain.dart';

class UnverifyBrandUseCase {
  final MarketplaceBrandRepository _repository;

  UnverifyBrandUseCase(this._repository);

  Future<MarketplaceBrand> execute(String id) => _repository.unverify(id);
}
