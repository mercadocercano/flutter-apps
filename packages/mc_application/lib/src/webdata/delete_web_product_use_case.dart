import 'package:mc_domain/mc_domain.dart';

class DeleteWebProductUseCase {
  final WebDataRepository _repository;

  DeleteWebProductUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteProduct(id);
}
