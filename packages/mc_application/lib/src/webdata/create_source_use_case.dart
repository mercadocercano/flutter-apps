import 'package:mc_domain/mc_domain.dart';

class CreateSourceUseCase {
  final WebDataRepository _repository;

  CreateSourceUseCase(this._repository);

  Future<WebSource> execute(WebSource source) =>
      _repository.createSource(source);
}
