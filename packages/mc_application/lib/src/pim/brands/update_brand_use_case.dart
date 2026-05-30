import 'package:mc_domain/mc_domain.dart';

class UpdateBrandUseCase {
  final MarketplaceBrandRepository _repository;

  UpdateBrandUseCase(this._repository);

  Future<MarketplaceBrand> execute(String id, UpdateBrandParams params) =>
      _repository.update(id, params);
}
