import 'package:mc_domain/mc_domain.dart';

class DeletePlanUseCase {
  final PlanRepository _repository;

  DeletePlanUseCase(this._repository);

  Future<void> execute(String id) => _repository.delete(id);
}
