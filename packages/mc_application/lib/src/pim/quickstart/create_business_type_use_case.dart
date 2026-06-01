import 'package:mc_domain/mc_domain.dart';

class CreateBusinessTypeUseCase {
  final QuickstartRepository _repository;

  CreateBusinessTypeUseCase(this._repository);

  Future<BusinessType> execute(BusinessType businessType) =>
      _repository.createBusinessType(businessType);
}
