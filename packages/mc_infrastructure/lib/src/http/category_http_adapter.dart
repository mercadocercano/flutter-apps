import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del CategoryPort — habla con pim-service via Kong.
class CategoryHttpAdapter implements CategoryPort {
  final McHttpClient _client;

  CategoryHttpAdapter(this._client);

  @override
  Future<List<Category>> listCategories({int page = 1, int pageSize = 50}) async {
    final response = await _client.get(
      ApiEndpoints.categories,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final items = data['items'] as List? ?? [];
    return items.map((json) => _map(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Category> getCategory(String categoryId) async {
    final response = await _client.get(ApiEndpoints.category(categoryId));
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<Category> createCategory({
    required String name,
    String? description,
    String? parentId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.categories,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (parentId != null) 'parent_id': parentId,
      },
    );
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    String? parentId,
    bool active = true,
  }) async {
    final response = await _client.put(
      ApiEndpoints.category(categoryId),
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (parentId != null) 'parent_id': parentId,
        'active': active,
      },
    );
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // PIM no tiene DELETE para categorías — usa PATCH deactivate
    await _client.patch('${ApiEndpoints.category(categoryId)}/deactivate');
  }

  Category _map(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        parentId: json['parent_id']?.toString(),
        active: json['active'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
