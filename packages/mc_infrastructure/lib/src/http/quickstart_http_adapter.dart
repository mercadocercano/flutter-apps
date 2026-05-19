import 'package:mc_application/mc_application.dart';
import 'mc_http_client.dart';
import 'api_endpoints.dart';

/// Implementación HTTP de QuickstartPort — habla con PIM via Kong.
///
/// Flujo correcto:
///   1. listBusinessTypes() → GET /pim/api/v1/quickstart/templates → muestra templates con nombres argentinos
///   2. listTemplates(businessTypeId: templateId) → mismo endpoint, busca template por id → popula selectCatalog
///   3. importFromBusinessType(businessTypeId: templateId) → POST /pim/api/v1/quickstart/apply
class QuickstartHttpAdapter implements QuickstartPort {
  final McHttpClient _client;

  // Cache en memoria para el ciclo de vida del adapter (evita 2 llamadas extra).
  List<Map<String, dynamic>>? _cachedTemplates;

  QuickstartHttpAdapter(this._client);

  // ─── listBusinessTypes: devuelve templates como "tipos de negocio" ───

  @override
  Future<List<BusinessTypeInfo>> listBusinessTypes() async {
    final templates = await _fetchTemplates();
    return templates.asMap().entries.map((e) {
      final m = e.value;
      return BusinessTypeInfo(
        id: m['id'] as String? ?? '',
        code: m['slug'] as String? ?? '',
        name: m['name'] as String? ?? '',
        icon: _iconFromSlug(m['slug'] as String? ?? ''),
        color: _colorFromSlug(m['slug'] as String? ?? ''),
        sortOrder: e.key,
      );
    }).toList();
  }

  // ─── listTemplates: carga template por id para el paso selectCatalog ───

  @override
  Future<List<QuickstartTemplate>> listTemplates({
    String? businessTypeId,
  }) async {
    final templates = await _fetchTemplates();
    final List<Map<String, dynamic>> source = businessTypeId != null
        ? templates.where((t) => t['id'] == businessTypeId).toList()
        : templates;

    return source.map(_parseTemplate).toList();
  }

  // ─── importFromBusinessType: aplica template al tenant ───

  @override
  Future<QuickstartImportResult> importFromBusinessType({
    required String businessTypeId,
  }) async {
    final response = await _client.post(
      ApiEndpoints.quickstartApply,
      data: {'template_id': businessTypeId},
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final result = _parseApplyResult(data);

    // El apply solo devuelve nombres, sin SKUs.
    // Fetchar los productos reales del tenant para obtener los variant SKUs.
    try {
      final prodResp = await _client.get(
        ApiEndpoints.products,
        queryParameters: {'page': 1, 'page_size': 200},
      );
      final prodData = prodResp.data as Map<String, dynamic>? ?? {};
      final rawProds = prodData['products'] as List? ?? prodData['items'] as List? ?? [];
      final products = rawProds.whereType<Map<String, dynamic>>().map((p) {
        final productSku = p['sku']?.toString() ?? '';
        // Convención PIM: variant default = product-SKU + "-DEF"
        final variantSku = productSku.isNotEmpty ? '$productSku-DEF' : '';
        return ImportedProduct(
          name: p['name']?.toString() ?? '',
          sku: variantSku,
        );
      }).where((p) => p.sku.isNotEmpty).toList();

      if (products.isNotEmpty) {
        return QuickstartImportResult(
          productsImported: result.productsImported,
          categoriesCreated: result.categoriesCreated,
          brandsImported: result.brandsImported,
          products: products,
        );
      }
    } catch (_) {
      // Si falla el fetch, usar el resultado original (sin SKUs)
    }

    return result;
  }

  // ─── helpers ───

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    if (_cachedTemplates != null) return _cachedTemplates!;
    final response = await _client.get(ApiEndpoints.quickstartTemplates);
    final data = response.data as Map<String, dynamic>? ?? {};
    final list = (data['templates'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((t) => t['is_active'] != false)
        .toList();
    _cachedTemplates = list;
    return list;
  }

  QuickstartTemplate _parseTemplate(Map<String, dynamic> m) {
    final rawCategories = m['categories'] as List? ?? [];
    final rawBrands = m['brands'] as List? ?? [];

    final categories = rawCategories
        .whereType<String>()
        .map((name) => TemplateCategory(
              id: name,
              name: name,
              slug: _slugify(name),
            ))
        .toList();

    final brands = rawBrands.map((b) {
      final name = b is Map ? (b['name'] as String? ?? '') : b.toString();
      return TemplateBrand(name: name);
    }).toList();

    return QuickstartTemplate(
      id: m['id'] as String? ?? '',
      businessTypeId: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      categories: categories,
      brands: brands,
      products: const [],
    );
  }

  QuickstartImportResult _parseApplyResult(Map<String, dynamic> data) {
    final createdProducts =
        (data['created_products'] as List? ?? []).whereType<String>().toList();
    final products = createdProducts
        .map((name) => ImportedProduct(name: name, sku: ''))
        .toList();

    return QuickstartImportResult(
      productsImported: (data['products_created'] as num?)?.toInt() ??
          (data['products_imported'] as num?)?.toInt() ??
          products.length,
      categoriesCreated: (data['categories_created'] as num?)?.toInt() ?? 0,
      brandsImported: (data['brands_created'] as num?)?.toInt() ?? 0,
      products: products,
    );
  }

  String _slugify(String s) =>
      s.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[áàä]'), 'a').replaceAll(RegExp(r'[éèë]'), 'e').replaceAll(RegExp(r'[íìï]'), 'i').replaceAll(RegExp(r'[óòö]'), 'o').replaceAll(RegExp(r'[úùü]'), 'u').replaceAll(RegExp(r'[ñ]'), 'n').replaceAll(RegExp(r'[^a-z0-9-]'), '');

  String _iconFromSlug(String slug) => switch (slug) {
        'almacen' => 'store',
        'kiosco' => 'storefront',
        'ferreteria' => 'hardware',
        'panaderia' => 'bakery_dining',
        'verduleria' => 'eco',
        'carniceria' => 'restaurant',
        'farmacia' => 'medical_services',
        'peluqueria' => 'content_cut',
        _ => 'store',
      };

  String _colorFromSlug(String slug) => switch (slug) {
        'almacen' => '#16A34A',
        'kiosco' => '#2563EB',
        'ferreteria' => '#DC2626',
        'panaderia' => '#D97706',
        'verduleria' => '#15803D',
        'carniceria' => '#7C3AED',
        'farmacia' => '#0891B2',
        'peluqueria' => '#DB2777',
        _ => '#4F46E5',
      };
}
