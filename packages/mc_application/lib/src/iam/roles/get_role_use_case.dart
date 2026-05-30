import 'package:mc_domain/mc_domain.dart';

class GetRoleUseCase {
  final RoleRepository _repository;

  GetRoleUseCase(this._repository);

  Future<Role> execute(String id) => _repository.getById(id);
}
