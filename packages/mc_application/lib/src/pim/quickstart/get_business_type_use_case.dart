import 'package:mc_domain/mc_domain.dart';

class GetBusinessTypeUseCase {
  final QuickstartRepository _repository;

  GetBusinessTypeUseCase(this._repository);

  Future<BusinessType> execute(String id) => _repository.getBusinessType(id);
}
