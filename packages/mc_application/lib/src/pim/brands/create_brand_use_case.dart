import 'package:mc_domain/mc_domain.dart';

class CreateBrandUseCase {
  final MarketplaceBrandRepository _repository;

  CreateBrandUseCase(this._repository);

  Future<MarketplaceBrand> execute(CreateBrandParams params) =>
      _repository.create(params);
}
