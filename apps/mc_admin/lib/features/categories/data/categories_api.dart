import '../../../core/api/kong_client.dart';

class CategoriesApi {
  final KongClient _kong;

  CategoriesApi(this._kong);

  Future<List<Map<String, dynamic>>> getAll({
    String? parentId,
    String? search,
    bool? active,
  }) async {
    final params = <String, dynamic>{};
    if (parentId != null) params['parent_id'] = parentId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (active != null) params['is_active'] = active;

    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/marketplace/categories',
      queryParameters: params.isNotEmpty ? params : null,
    );

    final data = response.data;
    if (data == null) return [];

    final items = data['categories'] ?? data['items'] ?? data['data'];
    if (items is List) return items.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _kong.post<Map<String, dynamic>>(
      '/pim/api/v1/marketplace/categories',
      data: data,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _kong.put<Map<String, dynamic>>(
      '/pim/api/v1/marketplace/categories/$id',
      data: data,
    );
    return response.data ?? {};
  }

  Future<void> delete(String id) async {
    await _kong.delete('/pim/api/v1/marketplace/categories/$id');
  }
}
