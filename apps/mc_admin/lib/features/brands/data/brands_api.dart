import '../../../core/api/kong_client.dart';

class BrandsApi {
  final KongClient _kong;

  BrandsApi(this._kong);

  Future<List<Map<String, dynamic>>> getAll({
    String? search,
    bool? verified,
    bool? active,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (verified != null) params['verification_status'] = verified;
    if (active != null) params['is_active'] = active;

    final response = await _kong.get<Map<String, dynamic>>(
      '/pim/api/v1/marketplace-brands',
      queryParameters: params.isNotEmpty ? params : null,
    );

    final data = response.data;
    if (data == null) return [];

    final items = data['brands'] ?? data['items'] ?? data['data'];
    if (items is List) {
      return items.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _kong.post<Map<String, dynamic>>(
      '/pim/api/v1/marketplace-brands',
      data: data,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _kong.put<Map<String, dynamic>>(
      '/pim/api/v1/marketplace-brands/$id',
      data: data,
    );
    return response.data ?? {};
  }

  Future<void> delete(String id) async {
    await _kong.delete('/pim/api/v1/marketplace-brands/$id');
  }

  Future<void> verify(String id) async {
    await _kong.put<void>('/pim/api/v1/marketplace-brands/$id/verify');
  }
}
