import 'package:mc_domain/mc_domain.dart';

class UpdateGlobalProductUseCase {
  final GlobalProductRepository _repository;

  UpdateGlobalProductUseCase(this._repository);

  Future<GlobalProduct> execute(GlobalProduct product) =>
      _repository.updateProduct(product);
}
