import 'package:mc_domain/mc_domain.dart';

class DeleteSourceUseCase {
  final WebDataRepository _repository;

  DeleteSourceUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteSource(id);
}
