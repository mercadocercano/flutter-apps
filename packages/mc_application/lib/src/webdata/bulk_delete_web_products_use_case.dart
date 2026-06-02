import 'package:mc_domain/mc_domain.dart';

class BulkDeleteWebProductsUseCase {
  final WebDataRepository _repository;

  BulkDeleteWebProductsUseCase(this._repository);

  Future<void> execute(List<String> ids) => _repository.bulkDeleteProducts(ids);
}
