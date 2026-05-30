import 'package:mc_domain/mc_domain.dart';

class GetRolesUseCase {
  final RoleRepository _repository;

  GetRolesUseCase(this._repository);

  Future<PaginatedResult<Role>> execute(
    int page,
    int pageSize, {
    RoleType? type,
    String? name,
    RoleStatus? status,
  }) {
    return _repository.getAll(page, pageSize, type: type, name: name, status: status);
  }
}
