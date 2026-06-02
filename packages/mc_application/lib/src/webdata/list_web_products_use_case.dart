import 'package:mc_domain/mc_domain.dart';

class ListWebProductsUseCase {
  final WebDataRepository _repository;

  ListWebProductsUseCase(this._repository);

  Future<PaginatedResult<WebProduct>> execute({
    String? sourceId,
    String? businessTypeId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.listProducts(
      sourceId: sourceId,
      businessTypeId: businessTypeId,
      page: page,
      pageSize: pageSize,
    );
  }
}
