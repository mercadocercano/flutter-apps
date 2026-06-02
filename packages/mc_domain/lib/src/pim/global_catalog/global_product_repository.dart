import '../../iam/paginated_result.dart';
import 'bulk_import_result.dart';
import 'global_product.dart';

/// Puerto de repositorio para el catálogo global de productos.
/// Implementado en mc_infrastructure por GlobalProductRepositoryImpl.
abstract interface class GlobalProductRepository {
  Future<PaginatedResult<GlobalProduct>> listProducts({
    String? search,
    String? businessTypeId,
    bool? isVerified,
    int page = 1,
    int pageSize = 20,
  });

  Future<GlobalProduct> getProduct(String id);

  Future<GlobalProduct> createProduct(GlobalProduct product);

  Future<GlobalProduct> updateProduct(GlobalProduct product);

  Future<void> deleteProduct(String id);

  Future<GlobalProduct> verifyProduct(String id);

  Future<GlobalProduct> unverifyProduct(String id);

  Future<BulkImportResult> bulkImport(List<Map<String, dynamic>> rows);
}
