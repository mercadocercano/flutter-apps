import 'package:mc_domain/mc_domain.dart';

class CreateRoleUseCase {
  final RoleRepository _repository;

  CreateRoleUseCase(this._repository);

  Future<Role> execute(UpsertRoleParams params) => _repository.create(params);
}
