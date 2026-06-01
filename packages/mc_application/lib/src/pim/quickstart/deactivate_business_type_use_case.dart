import 'package:mc_domain/mc_domain.dart';

class DeactivateBusinessTypeUseCase {
  final QuickstartRepository _repository;

  DeactivateBusinessTypeUseCase(this._repository);

  Future<BusinessType> execute(String id) =>
      _repository.deactivateBusinessType(id);
}
