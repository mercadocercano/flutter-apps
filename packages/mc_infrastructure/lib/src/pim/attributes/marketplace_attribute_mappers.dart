import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service ↔ entidades de dominio MarketplaceAttribute / AttributeValue.

/// Parsea lista paginada de atributos.
/// Formato real del backend:
/// {"items":[...],"total_count":N,"page":N,"page_size":N,"total_pages":N}
/// (sin sub-objeto "pagination"; "attributes" era el formato anterior)
PaginatedResult<MarketplaceAttribute> paginatedAttributesFromJson(
  Map<String, dynamic> json,
) {
  // Backend returns "items"; old code expected "attributes" — tolerate both.
  final rawItems = (json['items'] as List?) ?? (json['attributes'] as List?) ?? [];

  // Backend uses flat pagination keys (no "pagination" sub-object).
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
  final total = ((json['total_count'] ?? pagination['total']) as num?)?.toInt() ?? 0;
  final page = ((json['page'] ?? pagination['page']) as num?)?.toInt() ?? 1;
  final pageSize = ((json['page_size'] ?? pagination['page_size']) as num?)?.toInt() ?? 20;
  final totalPages = ((json['total_pages'] ?? pagination['total_pages']) as num?)?.toInt() ?? 1;

  return PaginatedResult<MarketplaceAttribute>(
    items: rawItems
        .cast<Map<String, dynamic>>()
        .map(attributeFromJson)
        .toList(),
    totalCount: total,
    page: page,
    pageSize: pageSize,
    totalPages: totalPages,
  );
}

/// Parsea un atributo desde JSON.
/// El backend no devuelve "description", "is_required" ni "values" en el listado.
/// Devuelve "is_required_for_listing" en lugar de "is_required",
/// y "is_filterable" sí coincide.
MarketplaceAttribute attributeFromJson(Map<String, dynamic> json) {
  final rawValues = (json['values'] as List?) ?? [];

  return MarketplaceAttribute(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    type: AttributeType.fromString(json['type'] as String?),
    description: json['description'] as String?,
    // Backend uses "is_required_for_listing"; fall back to "is_required" legacy.
    isRequired: ((json['is_required'] ?? json['is_required_for_listing']) as bool?) ?? false,
    isFilterable: (json['is_filterable'] as bool?) ?? false,
    values: rawValues
        .cast<Map<String, dynamic>>()
        .map(attributeValueFromJson)
        .toList(),
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

/// Serializa un MarketplaceAttribute a cuerpo JSON para POST/PUT.
Map<String, dynamic> attributeToJson(MarketplaceAttribute attr) {
  return <String, dynamic>{
    'name': attr.name,
    'slug': attr.slug,
    'type': attr.type.toApiString(),
    if (attr.description != null) 'description': attr.description,
    'is_required': attr.isRequired,
    'is_filterable': attr.isFilterable,
  };
}

/// Parsea un valor de atributo desde JSON.
AttributeValue attributeValueFromJson(Map<String, dynamic> json) {
  return AttributeValue(
    id: json['id'] as String,
    attributeId: json['attribute_id'] as String,
    value: json['value'] as String,
    label: json['label'] as String,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

/// Serializa un AttributeValue a cuerpo JSON para POST/PUT.
Map<String, dynamic> attributeValueToJson(AttributeValue value) {
  return <String, dynamic>{
    'value': value.value,
    'label': value.label,
    'sort_order': value.sortOrder,
  };
}

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
