import 'package:mc_domain/mc_domain.dart';

class VerifyGlobalProductUseCase {
  final GlobalProductRepository _repository;

  VerifyGlobalProductUseCase(this._repository);

  Future<GlobalProduct> execute(String id) => _repository.verifyProduct(id);
}
