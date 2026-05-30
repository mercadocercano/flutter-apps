import 'package:mc_domain/mc_domain.dart';

class GetPlanUseCase {
  final PlanRepository _repository;

  GetPlanUseCase(this._repository);

  Future<Plan> execute(String id) => _repository.getById(id);
}
