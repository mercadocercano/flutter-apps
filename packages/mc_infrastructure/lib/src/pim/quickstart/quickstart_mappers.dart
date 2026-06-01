import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service y ai-gateway ↔ entidades de dominio Quickstart.

// ---------------------------------------------------------------------------
// BusinessType
// ---------------------------------------------------------------------------

/// Parsea lista paginada de business types.
/// Formato esperado:
/// {"business_types":[...],"pagination":{"page":N,"page_size":N,"total":N,"total_pages":N}}
PaginatedResult<BusinessType> paginatedBusinessTypesFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['business_types'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

  final total = (pagination['total'] as num?)?.toInt() ?? 0;
  final page = (pagination['page'] as num?)?.toInt() ?? 1;
  final pageSize = (pagination['page_size'] as num?)?.toInt() ?? 20;
  final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

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
BusinessType businessTypeFromJson(Map<String, dynamic> json) {
  return BusinessType(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
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
/// Formato esperado: {"templates":[...]}
List<BusinessTypeTemplate> templatesFromJson(Map<String, dynamic> json) {
  final rawItems = (json['templates'] as List?) ?? [];
  return rawItems
      .cast<Map<String, dynamic>>()
      .map(templateFromJson)
      .toList();
}

/// Parsea un BusinessTypeTemplate desde JSON.
BusinessTypeTemplate templateFromJson(Map<String, dynamic> json) {
  final rawCategoryIds = (json['category_ids'] as List?) ?? [];
  final rawProductIds = (json['base_product_ids'] as List?) ?? [];

  return BusinessTypeTemplate(
    id: json['id'] as String,
    businessTypeId: json['business_type_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    categoryIds: rawCategoryIds.cast<String>(),
    baseProductIds: rawProductIds.cast<String>(),
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
