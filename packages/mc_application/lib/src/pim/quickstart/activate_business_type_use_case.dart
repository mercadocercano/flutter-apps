import 'package:mc_domain/mc_domain.dart';

class ActivateBusinessTypeUseCase {
  final QuickstartRepository _repository;

  ActivateBusinessTypeUseCase(this._repository);

  Future<BusinessType> execute(String id) =>
      _repository.activateBusinessType(id);
}
