import 'package:mc_domain/mc_domain.dart';

class DuplicateTemplateUseCase {
  final QuickstartRepository _repository;

  DuplicateTemplateUseCase(this._repository);

  Future<BusinessTypeTemplate> execute(String id) {
    return _repository.duplicateTemplate(id);
  }
}
