import 'package:mc_domain/mc_domain.dart';

/// Lista el catálogo curado de templates del Quickstart (los 21 base por rubro)
/// vía GET /pim/api/v1/quickstart/templates.
class ListQuickstartTemplatesUseCase {
  final QuickstartRepository _repository;

  ListQuickstartTemplatesUseCase(this._repository);

  Future<List<QuickstartTemplateSummary>> execute({String? status}) {
    return _repository.listQuickstartTemplates(status: status);
  }
}
