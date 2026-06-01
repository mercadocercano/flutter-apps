import 'package:mc_domain/mc_domain.dart';

class UpdateBusinessTypeUseCase {
  final QuickstartRepository _repository;

  UpdateBusinessTypeUseCase(this._repository);

  Future<BusinessType> execute(BusinessType businessType) =>
      _repository.updateBusinessType(businessType);
}
