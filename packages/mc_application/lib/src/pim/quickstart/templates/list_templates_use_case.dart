import 'package:mc_domain/mc_domain.dart';

class ListTemplatesUseCase {
  final QuickstartRepository _repository;

  ListTemplatesUseCase(this._repository);

  Future<List<BusinessTypeTemplate>> execute(String businessTypeId) {
    return _repository.listTemplates(businessTypeId);
  }
}
