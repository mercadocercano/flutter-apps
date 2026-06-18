import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../http/admin_http_client.dart';
import 'web_data_mappers.dart';

/// Implementación HTTP de WebDataRepository.
/// Consume /webdata/api/v1/... vía Kong.
class WebDataRepositoryImpl implements WebDataRepository {
  static const _base = '/webdata/api/v1';

  final KongClient _client;

  WebDataRepositoryImpl(this._client);

  // -------------------------------------------------------------------------
  // Dashboard
  // -------------------------------------------------------------------------

  @override
  Future<WebDataDashboardStats> getDashboardStats() async {
    final response = await _client.get<Map<String, dynamic>>('$_base/stats');
    return dashboardStatsFromJson(_requireData(response));
  }

  // -------------------------------------------------------------------------
  // Sources
  // -------------------------------------------------------------------------

  @override
  Future<PaginatedResult<WebSource>> listSources({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': status,
    };

    final response = await _client.get<Map<String, dynamic>>(
      '$_base/sources',
      queryParameters: params,
    );
    return paginatedSourcesFromJson(_requireData(response));
  }

  @override
  Future<WebSource> getSource(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/sources/$id');
    final data = _requireData(response);
    final sourceJson = data['source'] as Map<String, dynamic>? ?? data;
    return webSourceFromJson(sourceJson);
  }

  @override
  Future<WebSource> createSource(WebSource source) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/sources',
      data: webSourceToJson(source),
    );
    final data = _requireData(response);
    final sourceJson = data['source'] as Map<String, dynamic>? ?? data;
    return webSourceFromJson(sourceJson);
  }

  @override
  Future<WebSource> updateSource(WebSource source) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/sources/${source.id}',
      data: webSourceToJson(source),
    );
    final data = _requireData(response);
    final sourceJson = data['source'] as Map<String, dynamic>? ?? data;
    return webSourceFromJson(sourceJson);
  }

  @override
  Future<void> deleteSource(String id) async {
    await _client.delete<void>('$_base/sources/$id');
  }

  @override
  Future<WebJob> triggerSource(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/sources/$id/trigger',
    );
    final data = _requireData(response);
    final jobJson = data['job'] as Map<String, dynamic>? ?? data;
    return webJobFromJson(jobJson);
  }

  // -------------------------------------------------------------------------
  // Jobs
  // -------------------------------------------------------------------------

  @override
  Future<PaginatedResult<WebJob>> listJobs({
    String? status,
    String? sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': status,
      if (sourceId != null) 'source_id': sourceId,
    };

    final response = await _client.get<Map<String, dynamic>>(
      '$_base/jobs',
      queryParameters: params,
    );
    return paginatedJobsFromJson(_requireData(response));
  }

  @override
  Future<WebJob> getJob(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/jobs/$id');
    final data = _requireData(response);
    final jobJson = data['job'] as Map<String, dynamic>? ?? data;
    return webJobFromJson(jobJson);
  }

  @override
  Future<void> cancelJob(String id) async {
    await _client.post<void>('$_base/jobs/$id/cancel');
  }

  @override
  Future<WebJob> retryJob(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/jobs/$id/retry',
    );
    final data = _requireData(response);
    final jobJson = data['job'] as Map<String, dynamic>? ?? data;
    return webJobFromJson(jobJson);
  }

  // -------------------------------------------------------------------------
  // Products
  // -------------------------------------------------------------------------

  @override
  Future<PaginatedResult<WebProduct>> listProducts({
    String? sourceId,
    String? businessTypeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (sourceId != null) 'source_id': sourceId,
      if (businessTypeId != null) 'business_type_id': businessTypeId,
    };

    final response = await _client.get<Map<String, dynamic>>(
      '$_base/products',
      queryParameters: params,
    );
    return paginatedProductsFromJson(_requireData(response));
  }

  @override
  Future<WebProduct> getProduct(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/products/$id');
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return webProductFromJson(productJson);
  }

  @override
  Future<WebProduct> updateProduct(WebProduct product) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/products/${product.id}',
      data: webProductToJson(product),
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return webProductFromJson(productJson);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.delete<void>('$_base/products/$id');
  }

  @override
  Future<void> bulkDeleteProducts(List<String> ids) async {
    await _client.post<void>(
      '$_base/products/bulk-delete',
      data: <String, dynamic>{'ids': ids},
    );
  }

  @override
  Future<WebProduct> assignBusinessType(
    String id,
    String businessTypeId,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '$_base/products/$id/business-types',
      data: <String, dynamic>{'business_type_id': businessTypeId},
    );
    final data = _requireData(response);
    final productJson = data['product'] as Map<String, dynamic>? ?? data;
    return webProductFromJson(productJson);
  }

  @override
  Future<void> bulkAssignBusinessType(
    List<String> ids,
    String businessTypeId,
  ) async {
    await _client.post<void>(
      '$_base/products/bulk-assign-business-type',
      data: <String, dynamic>{
        'ids': ids,
        'business_type_id': businessTypeId,
      },
    );
  }

  @override
  Future<List<PricePoint>> getPriceHistory(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '$_base/products/$id/price-history',
    );
    return priceHistoryFromJson(_requireData(response));
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Map<String, dynamic> _requireData(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
