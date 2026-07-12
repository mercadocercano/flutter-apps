import '../../iam/paginated_result.dart';
import 'business_type.dart';
import 'business_type_template.dart';
import 'quickstart_template_product.dart';
import 'quickstart_template_summary.dart';
import 'template_analytics.dart';

/// Puerto de repositorio para el módulo Quickstart Dinámico.
///
/// Implementado en mc_infrastructure por QuickstartRepositoryImpl.
/// Todas las llamadas HTTP van a través de Kong.
abstract interface class QuickstartRepository {
  // --- Business Types ---

  Future<PaginatedResult<BusinessType>> listBusinessTypes({
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<BusinessType> getBusinessType(String id);

  Future<BusinessType> createBusinessType(BusinessType businessType);

  Future<BusinessType> updateBusinessType(BusinessType businessType);

  Future<void> deleteBusinessType(String id);

  Future<BusinessType> activateBusinessType(String id);

  Future<BusinessType> deactivateBusinessType(String id);

  // --- Templates ---

  /// Catálogo curado de templates del Quickstart (los 21 base por rubro),
  /// vía GET /pim/api/v1/quickstart/templates. [status] filtra ej. "active".
  Future<List<QuickstartTemplateSummary>> listQuickstartTemplates({
    String? status,
  });

  /// Productos sugeridos de un template del Quickstart (surtido computado desde
  /// global_products, fallback editorial), vía
  /// GET /pim/api/v1/quickstart/products/:businessTypeSlug.
  Future<List<QuickstartTemplateProduct>> getQuickstartTemplateProducts(
    String businessTypeSlug,
  );

  Future<List<BusinessTypeTemplate>> listTemplates(String businessTypeId);

  Future<BusinessTypeTemplate> getTemplate(String id);

  Future<BusinessTypeTemplate> createTemplate(BusinessTypeTemplate template);

  Future<BusinessTypeTemplate> updateTemplate(BusinessTypeTemplate template);

  Future<void> deleteTemplate(String id);

  Future<BusinessTypeTemplate> duplicateTemplate(String id);

  Future<TemplateAnalytics> getTemplateAnalytics(String id);

  // --- AI ---

  Future<BusinessTypeTemplate> generateTemplateWithAI(
    String description,
    String businessTypeId,
  );
}
