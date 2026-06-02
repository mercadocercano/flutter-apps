import 'package:mc_domain/mc_domain.dart';

class UpdateSourceUseCase {
  final WebDataRepository _repository;

  UpdateSourceUseCase(this._repository);

  Future<WebSource> execute(WebSource source) =>
      _repository.updateSource(source);
}
