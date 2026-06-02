import 'package:mc_domain/mc_domain.dart';

class GetSourceUseCase {
  final WebDataRepository _repository;

  GetSourceUseCase(this._repository);

  Future<WebSource> execute(String id) => _repository.getSource(id);
}
