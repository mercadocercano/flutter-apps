import '../../../core/api/kong_client.dart';
import '../domain/models/bulk_verify_result_model.dart';
import '../domain/models/enrichment_result_model.dart';
import '../domain/models/global_product_model.dart';
import 'global_products_api.dart';

class GlobalProductsRepository {
  late final GlobalProductsApi _api;

  GlobalProductsRepository(KongClient kong) : _api = GlobalProductsApi(kong);

  Future<GlobalProductsPage> getAll({
    String? search,
    String? businessType,
    bool? isVerified,
    bool? hasImage,
    int? minQuality,
    int? maxQuality,
    bool? massVerifiedOnly,
    int page = 1,
    int pageSize = 50,
  }) async {
    final json = await _api.getAll(
      search: search,
      businessType: businessType,
      isVerified: isVerified,
      hasImage: hasImage,
      minQuality: minQuality,
      maxQuality: maxQuality,
      massVerifiedOnly: massVerifiedOnly,
      page: page,
      pageSize: pageSize,
    );
    return GlobalProductsPage.fromJson(json);
  }

  Future<GlobalProduct> getById(String id) async {
    final json = await _api.getById(id);
    return GlobalProduct.fromJson(json);
  }

  Future<void> clearProductImage(String id) => _api.clearImageUrl(id);

  /// Rechaza la imagen activa del producto y marca para re-enriquecimiento.
  Future<void> rejectProductImage(String id) => _api.rejectImage(id);

  Future<List<String>> getBusinessTypes() => _api.getBusinessTypes();

  Future<BulkVerifyResult> bulkVerify({
    required List<String> ids,
    required bool verify,
  }) => _api.bulkVerify(ids: ids, verify: verify);

  Future<EnrichmentResult> runEnrichment({
    required List<String> productIds,
    bool forceReprocess = false,
  }) =>
      _api.runEnrichment(
        productIds: productIds,
        forceReprocess: forceReprocess,
      );
}
