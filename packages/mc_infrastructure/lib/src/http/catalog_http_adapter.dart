import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP del CatalogPort — habla con pim-service via Kong.
class CatalogHttpAdapter implements CatalogPort {
  final McHttpClient _client;

  CatalogHttpAdapter(this._client);

  @override
  Future<ProductPage> listProducts({
    int page = 1,
    int pageSize = 20,
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
        if (search != null) 'name': search,
        if (category != null) 'category_name': category,
        if (brand != null) 'brand_name': brand,
        if (status != null) 'status': status.name,
      },
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    // PIM devuelve "products" o "items"
    final rawItems = data['products'] as List? ?? data['items'] as List? ?? [];
    final items = rawItems
        .map((json) => _mapProduct(json as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    final totalCount = (pagination['total_items'] as num?)?.toInt() ??
        (data['total_count'] as num?)?.toInt() ??
        items.length;
    return ProductPage(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Product> getProduct(String productId) async {
    final response = await _client.get(ApiEndpoints.product(productId));
    final data = response.data as Map<String, dynamic>? ?? {};
    final productJson = data['product'] as Map<String, dynamic>? ?? data;

    // El detalle no incluye variantes — fetcharlas por separado.
    final variantsResp = await _client.get(ApiEndpoints.productVariants(productId));
    final variantsData = variantsResp.data as Map<String, dynamic>? ?? {};
    final rawVariants = variantsData['variants'] as List? ?? [];
    productJson['variants'] = rawVariants;

    return _mapProduct(productJson);
  }

  @override
  Future<Product?> getProductBySku(String sku) async {
    final page = await listProducts(search: sku, pageSize: 1);
    return page.items.firstOrNull;
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    final result = await listProducts(search: barcode, pageSize: 1);
    return result.items.firstOrNull;
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

  @override
  Future<Product> createProduct({
    required String name,
    String? description,
    String? categoryId,
    String? brandId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.products,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (brandId != null && brandId.isNotEmpty) 'brand_id': brandId,
      },
    );
    return _mapProduct(response.data as Map<String, dynamic>);
  }

  @override
  Future<Product> updateProduct({
    required String productId,
    required String name,
    String? description,
    String? categoryId,
    String? brandId,
    String status = 'active',
  }) async {
    final response = await _client.put(
      ApiEndpoints.product(productId),
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (brandId != null && brandId.isNotEmpty) 'brand_id': brandId,
        'status': status,
      },
    );
    return _mapProduct(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _client.delete(ApiEndpoints.product(productId));
  }

  Product _mapProduct(Map<String, dynamic> json) {
    var variants = (json['variants'] as List? ?? [])
        .map((v) => _mapVariant(v as Map<String, dynamic>))
        .toList();

    // El listado del PIM no incluye variantes — si price está presente en el
    // producto, construir una variante por defecto para que sea vendible en POS.
    // Convención PIM: variante default = SKU-producto + "-DEF" (ej. GAS-05AFDA84-DEF).
    // Si PIM ya devuelve el SKU de variante (via COALESCE), evitar doble "-DEF".
    if (variants.isEmpty && json['price'] != null) {
      final productSkuStr = json['sku']?.toString() ?? '';
      // Si el SKU ya termina en "-DEF" es el SKU de variante directo — usarlo sin agregar sufijo.
      final variantSkuStr = productSkuStr.toUpperCase().endsWith('-DEF')
          ? productSkuStr
          : (productSkuStr.isNotEmpty ? '$productSkuStr-DEF' : '');
      Sku? sku;
      if (variantSkuStr.isNotEmpty) {
        try { sku = Sku(variantSkuStr); } catch (_) {}
      }
      variants = [
        ProductVariant(
          id: json['id']?.toString() ?? '',
          productId: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          sku: sku,
          status: VariantStatus.active,
          isDefault: true,
          sortOrder: 0,
          price: Money.ars(_parseDouble(json['price'])),
          stock: (json['stock'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
        ),
      ];
    }

    // category y brand vienen como objetos {id, name, ...}, no como strings
    final category = json['category'];
    final brand = json['brand'];
    final categoryName = category is Map ? category['name'] as String? : json['category_name'] as String?;
    final brandName = brand is Map ? brand['name'] as String? : json['brand_name'] as String?;
    String? _str(dynamic v) {
      final s = v?.toString();
      return (s == null || s.isEmpty) ? null : s;
    }
    final brandBg = brand is Map ? _str(brand['background_color']) : null;
    final brandFg = brand is Map ? _str(brand['text_color']) : null;
    final brandFont = brand is Map ? _str(brand['typography']) : null;

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
      brandBg: brandBg,
      brandFg: brandFg,
      brandFont: brandFont,
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
