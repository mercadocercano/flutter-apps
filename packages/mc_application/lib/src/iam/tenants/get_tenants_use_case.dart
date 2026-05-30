import 'package:mc_domain/mc_domain.dart';

class GetTenantsUseCase {
  final TenantRepository _repository;

  GetTenantsUseCase(this._repository);

  Future<PaginatedResult<Tenant>> execute(
    int page,
    int pageSize, {
    TenantStatus? status,
    TenantType? type,
  }) {
    return _repository.getAll(page, pageSize, status: status, type: type);
  }
}
