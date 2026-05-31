import 'package:mc_domain/mc_domain.dart';

class DeleteCategoryUseCase {
  final MarketplaceCategoryRepository _repository;

  DeleteCategoryUseCase(this._repository);

  Future<void> execute(String id) => _repository.delete(id);
}
