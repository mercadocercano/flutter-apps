import 'package:mc_domain/mc_domain.dart';

class DeleteTemplateUseCase {
  final QuickstartRepository _repository;

  DeleteTemplateUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.deleteTemplate(id);
  }
}
