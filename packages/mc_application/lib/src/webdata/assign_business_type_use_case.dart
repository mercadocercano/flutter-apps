import 'package:mc_domain/mc_domain.dart';

class AssignBusinessTypeUseCase {
  final WebDataRepository _repository;

  AssignBusinessTypeUseCase(this._repository);

  Future<WebProduct> execute(String productId, String businessTypeId) =>
      _repository.assignBusinessType(productId, businessTypeId);
}
