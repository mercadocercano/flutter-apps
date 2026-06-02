import 'package:mc_domain/mc_domain.dart';

class UnverifyGlobalProductUseCase {
  final GlobalProductRepository _repository;

  UnverifyGlobalProductUseCase(this._repository);

  Future<GlobalProduct> execute(String id) => _repository.unverifyProduct(id);
}
