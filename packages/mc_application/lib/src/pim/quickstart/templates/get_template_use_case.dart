import 'package:mc_domain/mc_domain.dart';

class GetTemplateUseCase {
  final QuickstartRepository _repository;

  GetTemplateUseCase(this._repository);

  Future<BusinessTypeTemplate> execute(String id) {
    return _repository.getTemplate(id);
  }
}
