import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del BrandPort — habla con pim-service via Kong.
class BrandHttpAdapter implements BrandPort {
  final McHttpClient _client;

  BrandHttpAdapter(this._client);

  @override
  Future<BrandPage> listBrands({int page = 1, int pageSize = 20}) async {
    final response = await _client.get(
      ApiEndpoints.brands,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List? ?? [])
        .map((json) => _map(json as Map<String, dynamic>))
        .toList();
    final totalCount = (data['total_count'] as num?)?.toInt() ?? items.length;
    return BrandPage(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Brand> getBrand(String brandId) async {
    final response = await _client.get(ApiEndpoints.brand(brandId));
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<Brand> createBrand({required String name, String? description, String? color}) async {
    final response = await _client.post(
      ApiEndpoints.brands,
      data: {
        'name': name,
        'description': description,
        'color': color,
      },
    );
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<Brand> updateBrand({
    required String brandId,
    required String name,
    String? description,
    String status = 'active',
    String? color,
  }) async {
    final response = await _client.put(
      ApiEndpoints.brand(brandId),
      data: {
        'name': name,
        'description': description,
        'status': status,
        'color': color,
      },
    );
    return _map(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBrand(String brandId) async {
    await _client.delete(ApiEndpoints.brand(brandId));
  }

  Brand _map(Map<String, dynamic> json) {
    final colorRaw = json['color']?.toString() ?? '';
    return Brand(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      color: colorRaw.isNotEmpty ? colorRaw : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
