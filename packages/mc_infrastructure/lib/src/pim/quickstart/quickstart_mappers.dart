import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service y ai-gateway ↔ entidades de dominio Quickstart.

// ---------------------------------------------------------------------------
// BusinessType
// ---------------------------------------------------------------------------

/// Parsea lista paginada de business types.
/// Formato real del backend:
/// {"items":[...],"total_count":N,"page":N,"page_size":N,"total_pages":N}
/// (paginación flat, sin sub-objeto "pagination")
PaginatedResult<BusinessType> paginatedBusinessTypesFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['items'] as List?) ?? (json['business_types'] as List?) ?? [];

  // Backend uses flat pagination; fall back to "pagination" sub-object for compatibility.
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
  final total = ((json['total_count'] ?? pagination['total']) as num?)?.toInt() ?? 0;
  final page = ((json['page'] ?? pagination['page']) as num?)?.toInt() ?? 1;
  final pageSize = ((json['page_size'] ?? pagination['page_size']) as num?)?.toInt() ?? 20;
  final totalPages = ((json['total_pages'] ?? pagination['total_pages']) as num?)?.toInt() ?? 1;

  return PaginatedResult<BusinessType>(
    items: rawItems
        .cast<Map<String, dynamic>>()
        .map(businessTypeFromJson)
        .toList(),
    totalCount: total,
    page: page,
    pageSize: pageSize,
    totalPages: totalPages,
  );
}

/// Parsea un BusinessType desde JSON.
/// El backend devuelve "code" en lugar de "slug"; ambos son manejados.
BusinessType businessTypeFromJson(Map<String, dynamic> json) {
  return BusinessType(
    id: json['id'] as String,
    name: json['name'] as String,
    // Backend uses "code" as the identifier slug; fall back to "slug" legacy.
    slug: ((json['slug'] ?? json['code']) as String?) ?? '',
    description: json['description'] as String?,
    icon: (json['icon'] as String?) ?? '',
    isActive: (json['is_active'] as bool?) ?? true,
    templateCount: (json['template_count'] as num?)?.toInt() ?? 0,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

/// Serializa un BusinessType a cuerpo JSON para POST/PUT.
Map<String, dynamic> businessTypeToJson(BusinessType bt) {
  return <String, dynamic>{
    'name': bt.name,
    'slug': bt.slug,
    if (bt.description != null) 'description': bt.description,
    'icon': bt.icon,
    'is_active': bt.isActive,
  };
}

// ---------------------------------------------------------------------------
// BusinessTypeTemplate
// ---------------------------------------------------------------------------

/// Parsea una lista simple de templates.
/// Formato real del backend: {"items":[...],"total_count":N,...}
/// (el formato anterior esperaba {"templates":[...]})
List<BusinessTypeTemplate> templatesFromJson(Map<String, dynamic> json) {
  // Backend returns "items"; old code expected "templates" — tolerate both.
  final rawItems = (json['items'] as List?) ?? (json['templates'] as List?) ?? [];
  return rawItems
      .cast<Map<String, dynamic>>()
      .map(templateFromJson)
      .toList();
}

/// Parsea un BusinessTypeTemplate desde JSON.
/// El backend devuelve "categories" (lista de objetos {id,name,slug,level})
/// y "products" (lista de objetos {name,category_id,sku,price}) en lugar de
/// "category_ids" y "base_product_ids" como listas de strings.
BusinessTypeTemplate templateFromJson(Map<String, dynamic> json) {
  // category_ids: backend devuelve "categories" como lista de objetos.
  // Extraemos el "id" de cada objeto; los que tienen id vacío se descartan.
  List<String> categoryIds;
  final rawCategoryIds = json['category_ids'] as List?;
  if (rawCategoryIds != null) {
    categoryIds = rawCategoryIds.cast<String>();
  } else {
    final rawCategories = (json['categories'] as List?) ?? [];
    categoryIds = rawCategories
        .cast<Map<String, dynamic>>()
        .map((c) => c['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  // base_product_ids: backend devuelve "products" como lista de objetos.
  // No tienen IDs reales — los productos son sugerencias de nombre, no refs a UUIDs.
  List<String> baseProductIds;
  final rawProductIds = json['base_product_ids'] as List?;
  if (rawProductIds != null) {
    baseProductIds = rawProductIds.cast<String>();
  } else {
    // Products en el template son sugerencias sin ID; devolvemos lista vacía
    // para no romper el contrato del dominio.
    baseProductIds = const [];
  }

  return BusinessTypeTemplate(
    id: json['id'] as String,
    businessTypeId: json['business_type_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    categoryIds: categoryIds,
    baseProductIds: baseProductIds,
    isDuplicate: (json['is_duplicate'] as bool?) ?? false,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

/// Serializa un BusinessTypeTemplate a cuerpo JSON para POST/PUT.
Map<String, dynamic> templateToJson(BusinessTypeTemplate t) {
  return <String, dynamic>{
    'business_type_id': t.businessTypeId,
    'name': t.name,
    if (t.description != null) 'description': t.description,
    'category_ids': t.categoryIds,
    'base_product_ids': t.baseProductIds,
  };
}

// ---------------------------------------------------------------------------
// TemplateAnalytics
// ---------------------------------------------------------------------------

/// Parsea TemplateAnalytics desde JSON.
/// Formato esperado: {"template_id":...,"tenants_count":N,"last_activated_at":...,
///                    "completion_rate":0.75}
TemplateAnalytics templateAnalyticsFromJson(
  String templateId,
  Map<String, dynamic> json,
) {
  final analyticsData =
      json['analytics'] as Map<String, dynamic>? ?? json;

  return TemplateAnalytics(
    templateId: templateId,
    tenantsCount: (analyticsData['tenants_count'] as num?)?.toInt() ?? 0,
    lastActivatedAt: analyticsData['last_activated_at'] != null
        ? _parseDate(analyticsData['last_activated_at'])
        : null,
    completionRate:
        (analyticsData['completion_rate'] as num?)?.toDouble() ?? 0.0,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
