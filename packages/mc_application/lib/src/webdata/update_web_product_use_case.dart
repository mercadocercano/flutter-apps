import 'package:mc_domain/mc_domain.dart';

class UpdateWebProductUseCase {
  final WebDataRepository _repository;

  UpdateWebProductUseCase(this._repository);

  Future<WebProduct> execute(WebProduct product) =>
      _repository.updateProduct(product);
}
