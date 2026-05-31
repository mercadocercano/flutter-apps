import 'package:mc_domain/mc_domain.dart';

class CreateCategoryUseCase {
  final MarketplaceCategoryRepository _repository;

  CreateCategoryUseCase(this._repository);

  Future<MarketplaceCategory> execute(CreateCategoryParams params) =>
      _repository.create(params);
}
