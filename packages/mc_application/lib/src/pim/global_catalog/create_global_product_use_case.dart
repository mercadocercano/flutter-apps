import 'package:mc_domain/mc_domain.dart';

class CreateGlobalProductUseCase {
  final GlobalProductRepository _repository;

  CreateGlobalProductUseCase(this._repository);

  Future<GlobalProduct> execute(GlobalProduct product) =>
      _repository.createProduct(product);
}
