import 'package:mc_domain/mc_domain.dart';

class UpdateTemplateUseCase {
  final QuickstartRepository _repository;

  UpdateTemplateUseCase(this._repository);

  Future<BusinessTypeTemplate> execute(BusinessTypeTemplate template) {
    return _repository.updateTemplate(template);
  }
}
