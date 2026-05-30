import 'package:mc_domain/mc_domain.dart';

class GetPlansUseCase {
  final PlanRepository _repository;

  GetPlansUseCase(this._repository);

  Future<PaginatedResult<Plan>> execute(
    int page,
    int pageSize, {
    PlanType? type,
    String? name,
    PlanStatus? status,
  }) {
    return _repository.getAll(page, pageSize, type: type, name: name, status: status);
  }
}
