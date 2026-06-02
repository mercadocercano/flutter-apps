import 'package:mc_domain/mc_domain.dart';

class DeleteGlobalProductUseCase {
  final GlobalProductRepository _repository;

  DeleteGlobalProductUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteProduct(id);
}
