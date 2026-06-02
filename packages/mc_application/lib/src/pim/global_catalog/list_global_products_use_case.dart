import 'package:mc_domain/mc_domain.dart';

class ListGlobalProductsUseCase {
  final GlobalProductRepository _repository;

  ListGlobalProductsUseCase(this._repository);

  Future<PaginatedResult<GlobalProduct>> execute(
    int page,
    int pageSize, {
    String? search,
    String? businessTypeId,
    bool? isVerified,
  }) {
    return _repository.listProducts(
      search: search,
      businessTypeId: businessTypeId,
      isVerified: isVerified,
      page: page,
      pageSize: pageSize,
    );
  }
}
