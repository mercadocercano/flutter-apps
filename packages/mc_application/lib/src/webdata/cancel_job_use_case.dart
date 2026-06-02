import 'package:mc_domain/mc_domain.dart';

class CancelJobUseCase {
  final WebDataRepository _repository;

  CancelJobUseCase(this._repository);

  Future<void> execute(String id) => _repository.cancelJob(id);
}
