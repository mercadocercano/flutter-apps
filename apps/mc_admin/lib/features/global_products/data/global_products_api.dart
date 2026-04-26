import '../../../core/api/kong_client.dart';

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

  Future<List<String>> getBusinessTypes() async {
    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/global-catalog/business-types',
    );
    final data = response.data ?? {};
    final raw = data['business_types'] as List? ?? [];
    return raw.cast<String>();
  }
}
