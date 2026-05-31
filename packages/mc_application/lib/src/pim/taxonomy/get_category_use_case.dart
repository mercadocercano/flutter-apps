import 'package:mc_domain/mc_domain.dart';

class GetCategoryUseCase {
  final MarketplaceCategoryRepository _repository;

  GetCategoryUseCase(this._repository);

  Future<MarketplaceCategory> execute(String id) =>
      _repository.getById(id);
}
