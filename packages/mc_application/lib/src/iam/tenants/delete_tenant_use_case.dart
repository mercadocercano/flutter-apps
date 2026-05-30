import 'package:mc_domain/mc_domain.dart';

class DeleteTenantUseCase {
  final TenantRepository _repository;

  DeleteTenantUseCase(this._repository);

  Future<void> execute(String id) => _repository.delete(id);
}
