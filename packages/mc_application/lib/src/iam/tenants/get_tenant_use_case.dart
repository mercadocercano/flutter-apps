import 'package:mc_domain/mc_domain.dart';

class GetTenantUseCase {
  final TenantRepository _repository;

  GetTenantUseCase(this._repository);

  Future<Tenant> execute(String id) => _repository.getById(id);
}
