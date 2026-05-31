import 'package:mc_domain/mc_domain.dart';

class UpdateCategoryUseCase {
  final MarketplaceCategoryRepository _repository;

  UpdateCategoryUseCase(this._repository);

  Future<MarketplaceCategory> execute(String id, UpdateCategoryParams params) =>
      _repository.update(id, params);
}
