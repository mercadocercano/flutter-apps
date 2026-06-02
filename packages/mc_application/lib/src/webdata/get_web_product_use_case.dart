import 'package:mc_domain/mc_domain.dart';

class GetWebProductUseCase {
  final WebDataRepository _repository;

  GetWebProductUseCase(this._repository);

  Future<WebProduct> execute(String id) => _repository.getProduct(id);
}
