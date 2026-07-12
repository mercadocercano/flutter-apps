import 'package:mc_domain/mc_domain.dart';

/// Trae los productos sugeridos de un template del Quickstart (surtido
/// computado desde global_products, fallback editorial) vía
/// GET /pim/api/v1/quickstart/products/:businessTypeSlug.
///
/// Usado por el catálogo de templates para mostrar el surtido al expandir un
/// template (carga lazy on-demand).
class GetQuickstartTemplateProductsUseCase {
  final QuickstartRepository _repository;

  GetQuickstartTemplateProductsUseCase(this._repository);

  Future<List<QuickstartTemplateProduct>> execute(String businessTypeSlug) {
    return _repository.getQuickstartTemplateProducts(businessTypeSlug);
  }
}
