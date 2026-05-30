import 'package:mc_domain/mc_domain.dart';

class GetTenantsUseCase {
  final TenantRepository _repository;

  GetTenantsUseCase(this._repository);

  Future<PaginatedResult<Tenant>> execute(
    int page,
    int pageSize, {
    String? name,
    TenantStatus? status,
    TenantType? type,
  }) {
    return _repository.getAll(page, pageSize, name: name, status: status, type: type);
  }
}
