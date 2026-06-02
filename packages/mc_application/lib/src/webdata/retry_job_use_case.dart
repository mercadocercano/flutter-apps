import 'package:mc_domain/mc_domain.dart';

class RetryJobUseCase {
  final WebDataRepository _repository;

  RetryJobUseCase(this._repository);

  Future<WebJob> execute(String id) => _repository.retryJob(id);
}
