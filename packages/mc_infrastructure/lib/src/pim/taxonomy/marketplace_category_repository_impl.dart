import 'package:dio/dio.dart';
import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';
import 'category_mappers.dart';

/// Implementación HTTP de MarketplaceCategoryRepository.
/// Consume /pim/api/v1/marketplace/categories vía Kong.
class MarketplaceCategoryRepositoryImpl
    implements MarketplaceCategoryRepository {
  static const _base = '/pim/api/v1/marketplace/categories';

  final KongClient _client;

  MarketplaceCategoryRepositoryImpl(this._client);

  @override
  Future<PaginatedResult<MarketplaceCategory>> getAll(
    int page,
    int pageSize, {
    String? name,
    String? parentId,
  }) async {
    final offset = (page - 1) * pageSize;
    final params = <String, dynamic>{
      'offset': offset,
      'limit': pageSize,
      if (name != null && name.isNotEmpty) 'search': name,
      if (parentId != null) 'parent_id': parentId,
    };

    final response = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: params,
    );

    return paginatedCategoriesFromJson(_requireData(response));
  }

  @override
  Future<CategoryTree> getTree() async {
    final response = await _client.get<Map<String, dynamic>>('$_base/tree');
    return treeFromJson(_requireData(response));
  }

  @override
  Future<MarketplaceCategory> getById(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('$_base/$id');
    final data = _requireData(response);
    // Single: {"category": {...}}
    final catJson = data['category'] as Map<String, dynamic>? ?? data;
    return categoryFromJson(catJson);
  }

  @override
  Future<MarketplaceCategory> create(CreateCategoryParams params) async {
    final body = <String, dynamic>{
      'name': params.name,
      'slug': params.slug,
      'is_active': params.isActive,
      'sort_order': params.sortOrder,
      if (params.description != null) 'description': params.description,
      if (params.parentId != null) 'parent_id': params.parentId,
    };

    final response = await _client.post<Map<String, dynamic>>(
      _base,
      data: body,
    );
    final data = _requireData(response);
    final catJson = data['category'] as Map<String, dynamic>? ?? data;
    return categoryFromJson(catJson);
  }

  @override
  Future<MarketplaceCategory> update(
    String id,
    UpdateCategoryParams params,
  ) async {
    final body = <String, dynamic>{
      if (params.name != null) 'name': params.name,
      if (params.slug != null) 'slug': params.slug,
      if (params.description != null) 'description': params.description,
      if (params.parentId != null) 'parent_id': params.parentId,
      if (params.isActive != null) 'is_active': params.isActive,
      if (params.sortOrder != null) 'sort_order': params.sortOrder,
    };

    final response = await _client.put<Map<String, dynamic>>(
      '$_base/$id',
      data: body,
    );
    final data = _requireData(response);
    final catJson = data['category'] as Map<String, dynamic>? ?? data;
    return categoryFromJson(catJson);
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete<void>('$_base/$id');
  }

  Map<String, dynamic> _requireData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw Exception('Respuesta vacía del servidor');
    return data;
  }
}
