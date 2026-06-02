import 'package:mc_domain/mc_domain.dart';

class GetJobUseCase {
  final WebDataRepository _repository;

  GetJobUseCase(this._repository);

  Future<WebJob> execute(String id) => _repository.getJob(id);
}
