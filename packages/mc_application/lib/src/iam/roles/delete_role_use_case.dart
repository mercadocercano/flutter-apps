import 'package:mc_domain/mc_domain.dart';

class DeleteRoleUseCase {
  final RoleRepository _repository;

  DeleteRoleUseCase(this._repository);

  Future<void> execute(String id) => _repository.delete(id);
}
