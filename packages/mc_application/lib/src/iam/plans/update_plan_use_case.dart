import 'package:mc_domain/mc_domain.dart';

class UpdatePlanUseCase {
  final PlanRepository _repository;

  UpdatePlanUseCase(this._repository);

  Future<Plan> execute(String id, UpsertPlanParams params) =>
      _repository.update(id, params);
}
