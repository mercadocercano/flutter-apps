import 'package:mc_domain/mc_domain.dart';

class UpdateTenantUseCase {
  final TenantRepository _repository;

  UpdateTenantUseCase(this._repository);

  Future<Tenant> execute(String id, UpdateTenantParams params) =>
      _repository.update(id, params);
}
