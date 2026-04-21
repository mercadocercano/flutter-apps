import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del CatalogPort — habla con pim-service via Kong.
class CatalogHttpAdapter implements CatalogPort {
  final McHttpClient _client;

  CatalogHttpAdapter(this._client);

  @override
  Future<List<Product>> listProducts({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? category,
    String? brand,
    ProductStatus? status,
  }) async {
    final response = await _client.get(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (brand != null) 'brand': brand,
        if (status != null) 'status': status.name,
      },
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    // PIM devuelve "products", no "items"
    final products = data['products'] as List? ?? data['items'] as List? ?? [];
    return products
        .map((json) => _mapProduct(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product> getProduct(String productId) async {
    final response = await _client.get(ApiEndpoints.product(productId));
    final data = response.data as Map<String, dynamic>? ?? {};
    return _mapProduct(data['product'] as Map<String, dynamic>? ?? data);
  }

  @override
  Future<Product?> getProductBySku(String sku) async {
    final products = await listProducts(search: sku, pageSize: 1);
    return products.firstOrNull;
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    final products = await listProducts(search: barcode, pageSize: 1);
    return products.firstOrNull;
  }

  @override
  Future<int> countProducts() async {
    final response = await _client.get(
      ApiEndpoints.products,
      queryParameters: {'page': 1, 'page_size': 1},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    return pagination['total_items'] ?? data['total_count'] ?? 0;
  }

  Product _mapProduct(Map<String, dynamic> json) {
    final variants = (json['variants'] as List? ?? [])
        .map((v) => _mapVariant(v as Map<String, dynamic>))
        .toList();

    // category y brand vienen como objetos {id, name}, no como strings
    final category = json['category'];
    final brand = json['brand'];
    final categoryName = category is Map ? category['name'] as String? : json['category_name'] as String?;
    final brandName = brand is Map ? brand['name'] as String? : json['brand_name'] as String?;

    // tenant_id no viene en la respuesta del PIM
    final tenantIdStr = json['tenant_id']?.toString() ?? '';

    return Product(
      id: json['id']?.toString() ?? '',
      tenantId: tenantIdStr.isNotEmpty ? TenantId(tenantIdStr) : TenantId('unknown'),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      categoryName: categoryName,
      brandName: brandName,
      status: _parseProductStatus(json['status']?.toString()),
      variants: variants,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  ProductVariant _mapVariant(Map<String, dynamic> json) {
    // SKU puede tener formato inválido — proteger con try-catch
    Sku? sku;
    final skuStr = json['sku']?.toString();
    if (skuStr != null && skuStr.isNotEmpty) {
      try {
        sku = Sku(skuStr);
      } catch (_) {
        // SKU con formato inválido — usar null
      }
    }

    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: sku,
      status: _parseVariantStatus(json['status']?.toString()),
      isDefault: json['is_default'] == true,
      sortOrder: (json['sort_order'] ?? 0) as int,
      price: Money.ars(_parseDouble(json['price'])),
      stock: (json['stock'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  ProductStatus _parseProductStatus(String? status) => switch (status) {
        'active' => ProductStatus.active,
        'inactive' => ProductStatus.inactive,
        'pending' => ProductStatus.pending,
        'discontinued' => ProductStatus.discontinued,
        'deleted' => ProductStatus.deleted,
        _ => ProductStatus.draft,
      };

  VariantStatus _parseVariantStatus(String? status) => switch (status) {
        'active' => VariantStatus.active,
        'inactive' => VariantStatus.inactive,
        'discontinued' => VariantStatus.discontinued,
        'deleted' => VariantStatus.deleted,
        _ => VariantStatus.active,
      };
}
