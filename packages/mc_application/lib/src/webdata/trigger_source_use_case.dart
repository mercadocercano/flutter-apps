import 'package:mc_domain/mc_domain.dart';

class TriggerSourceUseCase {
  final WebDataRepository _repository;

  TriggerSourceUseCase(this._repository);

  Future<WebJob> execute(String id) => _repository.triggerSource(id);
}
