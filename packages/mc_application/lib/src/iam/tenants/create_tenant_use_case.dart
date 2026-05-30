import 'package:mc_domain/mc_domain.dart';

class CreateTenantUseCase {
  final TenantRepository _repository;

  CreateTenantUseCase(this._repository);

  Future<Tenant> execute(CreateTenantParams params) =>
      _repository.create(params);
}
