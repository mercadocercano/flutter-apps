import '../iam/paginated_result.dart';
import 'price_point.dart';
import 'web_data_dashboard_stats.dart';
import 'web_job.dart';
import 'web_product.dart';
import 'web_source.dart';

/// Puerto de repositorio para el módulo Web Data.
///
/// Implementado en mc_infrastructure por WebDataRepositoryImpl.
/// Todas las llamadas HTTP van a través de Kong (webdata-service).
abstract interface class WebDataRepository {
  // --- Dashboard ---

  Future<WebDataDashboardStats> getDashboardStats();

  // --- Sources ---

  Future<PaginatedResult<WebSource>> listSources({
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<WebSource> getSource(String id);

  Future<WebSource> createSource(WebSource source);

  Future<WebSource> updateSource(WebSource source);

  Future<void> deleteSource(String id);

  /// Inicia un job de scraping manual para la fuente indicada.
  Future<WebJob> triggerSource(String id);

  // --- Jobs ---

  Future<PaginatedResult<WebJob>> listJobs({
    String? status,
    String? sourceId,
    int page = 1,
    int pageSize = 20,
  });

  Future<WebJob> getJob(String id);

  Future<void> cancelJob(String id);

  /// Reintenta un job fallido, generando un nuevo job.
  Future<WebJob> retryJob(String id);

  // --- Products ---

  Future<PaginatedResult<WebProduct>> listProducts({
    String? sourceId,
    String? businessTypeId,
    int page = 1,
    int pageSize = 20,
  });

  Future<WebProduct> getProduct(String id);

  Future<WebProduct> updateProduct(WebProduct product);

  Future<void> deleteProduct(String id);

  Future<void> bulkDeleteProducts(List<String> ids);

  Future<WebProduct> assignBusinessType(String id, String businessTypeId);

  Future<void> bulkAssignBusinessType(
    List<String> ids,
    String businessTypeId,
  );

  Future<List<PricePoint>> getPriceHistory(String id);
}
