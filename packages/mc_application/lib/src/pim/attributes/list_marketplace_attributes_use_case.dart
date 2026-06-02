import 'package:mc_domain/mc_domain.dart';

class ListMarketplaceAttributesUseCase {
  final MarketplaceAttributeRepository _repository;

  ListMarketplaceAttributesUseCase(this._repository);

  Future<PaginatedResult<MarketplaceAttribute>> execute(
    int page,
    int pageSize, {
    String? search,
    AttributeType? type,
  }) {
    return _repository.listAttributes(
      search: search,
      type: type,
      page: page,
      pageSize: pageSize,
    );
  }
}
