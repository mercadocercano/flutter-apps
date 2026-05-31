import 'package:mc_domain/mc_domain.dart';

class GetCategoryTreeUseCase {
  final MarketplaceCategoryRepository _repository;

  GetCategoryTreeUseCase(this._repository);

  Future<CategoryTree> execute() => _repository.getTree();
}
