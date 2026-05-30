import 'package:mc_domain/mc_domain.dart';

class ToggleTenantStatusUseCase {
  final TenantRepository _repository;

  ToggleTenantStatusUseCase(this._repository);

  Future<Tenant> execute(String id, TenantStatus newStatus) {
    return _repository.toggleStatus(id, newStatus);
  }
}
