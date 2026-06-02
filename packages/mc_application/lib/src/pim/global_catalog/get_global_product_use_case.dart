import 'package:mc_domain/mc_domain.dart';

class GetGlobalProductUseCase {
  final GlobalProductRepository _repository;

  GetGlobalProductUseCase(this._repository);

  Future<GlobalProduct> execute(String id) => _repository.getProduct(id);
}
