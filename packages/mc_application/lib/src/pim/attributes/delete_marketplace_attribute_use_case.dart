import 'package:mc_domain/mc_domain.dart';

class DeleteMarketplaceAttributeUseCase {
  final MarketplaceAttributeRepository _repository;

  DeleteMarketplaceAttributeUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteAttribute(id);
}
