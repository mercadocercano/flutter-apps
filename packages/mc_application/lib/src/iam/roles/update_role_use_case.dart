import 'package:mc_domain/mc_domain.dart';

class UpdateRoleUseCase {
  final RoleRepository _repository;

  UpdateRoleUseCase(this._repository);

  Future<Role> execute(String id, UpsertRoleParams params) =>
      _repository.update(id, params);
}
