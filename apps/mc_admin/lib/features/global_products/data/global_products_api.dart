import '../../../core/api/kong_client.dart';
import '../domain/models/enrichment_result_model.dart';

class GlobalProductsApi {
  final KongClient _kong;

  GlobalProductsApi(this._kong);

  Future<Map<String, dynamic>> getAll({
    String? search,
    String? businessType,
    bool? isVerified,
    bool? hasImage,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (businessType != null && businessType.isNotEmpty) {
      params['business_type'] = businessType;
    }
    if (isVerified != null) params['is_verified'] = isVerified;
    if (hasImage == true) params['has_image'] = true;

    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/global-catalog/products',
      queryParameters: params,
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/global-catalog/products/$id',
    );
    return response.data ?? {};
  }

  Future<void> clearImageUrl(String id) async {
    await _kong.put<void>(
      '/pim/api/v1/global-catalog/products/$id',
      data: {'image_url': ''},
    );
  }

  Future<List<String>> getBusinessTypes() async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/global-catalog/business-types',
    );
    final data = response.data ?? {};
    final raw = data['business_types'] as List? ?? [];
    return raw.cast<String>();
  }

  /// Rechaza la imagen actual del producto y solicita re-enriquecimiento
  /// en el próximo ciclo del webdata-service.
  ///
  /// POST /webdata/api/v1/enrichment/reject  { "product_id": productId }
  Future<void> rejectImage(String productId) async {
    await _kong.post<void>(
      '/webdata/api/v1/enrichment/reject',
      data: {'product_id': productId},
    );
  }

  Future<EnrichmentResult> runEnrichment({
    required List<String> productIds,
    bool forceReprocess = false,
  }) async {
    final response = await _kong.post<Map<String, dynamic>>(
      '/webdata/api/v1/enrichment/run',
      data: {
        'product_ids': productIds,
        'force_reprocess': forceReprocess,
      },
    );
    return EnrichmentResult.fromJson(response.data ?? {});
  }
}
