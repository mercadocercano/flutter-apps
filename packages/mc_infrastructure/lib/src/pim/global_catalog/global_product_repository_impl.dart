import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';
import 'global_product_mappers.dart';

/// Implementación HTTP de GlobalProductRepository.
/// Consume /pim/api/v1/global-catalog/products vía Kong.
class GlobalProductRepositoryImpl implements GlobalProductRepository {
  static const _base = '/pim/api/v1/global-catalog/products';

  final KongClient _client;

  GlobalProductRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<GlobalProduct>> listProducts({
    String? search,
    String? businessTypeId,
    bool? isVerified,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (businessTypeId != null) 'business_type_id': businessTypeId,
      if (isVerified != null) 'is_verified': isVerified,
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    return paginatedGlobalProductsFromJson(_requireData(response));
  }

  @override
  Future<GlobalProduct> getProduct(String id) async {
    final response = await _client.get<Map<String, dynamic>>('$_base/$id');
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return globalProductFromJson(productJson);
  }

  @override
  Future<GlobalProduct> createProduct(GlobalProduct product) async {
    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: globalProductToJson(product),
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return globalProductFromJson(productJson);
  }

  @override
  Future<GlobalProduct> updateProduct(GlobalProduct product) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/${product.id}',
      data: globalProductToJson(product),
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return globalProductFromJson(productJson);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  @override
  Future<GlobalProduct> verifyProduct(String id) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '$_base/$id/verify',
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return globalProductFromJson(productJson);
  }

  @override
  Future<GlobalProduct> unverifyProduct(String id) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '$_base/$id/unverify',
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return globalProductFromJson(productJson);
  }

  @override
  Future<BulkImportResult> bulkImport(List<Map<String, dynamic>> rows) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/bulk-import',
      data: {'products': rows},
    );
    return bulkImportResultFromJson(_requireData(response));
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
