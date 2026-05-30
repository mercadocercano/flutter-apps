import 'package:mc_domain/mc_domain.dart';

class CreatePlanUseCase {
  final PlanRepository _repository;

  CreatePlanUseCase(this._repository);

  Future<Plan> execute(UpsertPlanParams params) => _repository.create(params);
}
