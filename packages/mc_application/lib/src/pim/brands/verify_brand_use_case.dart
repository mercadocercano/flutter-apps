import 'package:mc_domain/mc_domain.dart';

class VerifyBrandUseCase {
  final MarketplaceBrandRepository _repository;

  VerifyBrandUseCase(this._repository);

  Future<MarketplaceBrand> execute(String id) => _repository.verify(id);
}
