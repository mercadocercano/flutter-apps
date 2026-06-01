import 'package:mc_domain/mc_domain.dart';

class CreateTemplateUseCase {
  final QuickstartRepository _repository;

  CreateTemplateUseCase(this._repository);

  Future<BusinessTypeTemplate> execute(BusinessTypeTemplate template) {
    return _repository.createTemplate(template);
  }
}
