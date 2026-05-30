import 'package:mc_domain/mc_domain.dart';

class DeleteBrandUseCase {
  final MarketplaceBrandRepository _repository;

  DeleteBrandUseCase(this._repository);

  Future<void> execute(String id) => _repository.delete(id);
}
