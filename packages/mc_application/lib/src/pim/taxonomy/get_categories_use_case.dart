import 'package:mc_domain/mc_domain.dart';

class GetCategoriesUseCase {
  final MarketplaceCategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<PaginatedResult<MarketplaceCategory>> execute(
    int page,
    int pageSize, {
    String? name,
    String? parentId,
  }) {
    return _repository.getAll(
      page,
      pageSize,
      name: name,
      parentId: parentId,
    );
  }
}
