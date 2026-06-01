import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio GlobalProduct / BulkImportResult.

/// Parsea lista paginada de productos globales.
/// Formato esperado:
/// {"products":[...],"pagination":{"page":N,"page_size":N,"total":N,"total_pages":N}}
PaginatedResult<GlobalProduct> paginatedGlobalProductsFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['products'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

  final total = (pagination['total'] as num?)?.toInt() ?? 0;
  final page = (pagination['page'] as num?)?.toInt() ?? 1;
  final pageSize = (pagination['page_size'] as num?)?.toInt() ?? 20;
  final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

  return PaginatedResult<GlobalProduct>(
    items: rawItems
        .cast<Map<String, dynamic>>()
        .map(globalProductFromJson)
        .toList(),
    totalCount: total,
    page: page,
    pageSize: pageSize,
    totalPages: totalPages,
  );
}

/// Parsea un producto global desde JSON.
GlobalProduct globalProductFromJson(Map<String, dynamic> json) {
  final rawBusinessTypeIds = (json['business_type_ids'] as List?) ?? [];
  final rawAttributes =
      (json['attributes'] as Map<String, dynamic>?) ?? const {};

  return GlobalProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: json['sku'] as String,
    barcode: json['barcode'] as String?,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    businessTypeIds: rawBusinessTypeIds.cast<String>(),
    categoryId: json['category_id'] as String?,
    attributes: rawAttributes,
    isVerified: (json['is_verified'] as bool?) ?? false,
    verifiedAt: _parseDateOrNull(json['verified_at']),
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

/// Serializa un GlobalProduct a cuerpo JSON para POST/PUT.
Map<String, dynamic> globalProductToJson(GlobalProduct product) {
  return <String, dynamic>{
    'name': product.name,
    'sku': product.sku,
    if (product.barcode != null) 'barcode': product.barcode,
    if (product.description != null) 'description': product.description,
    if (product.imageUrl != null) 'image_url': product.imageUrl,
    if (product.categoryId != null) 'category_id': product.categoryId,
    'business_type_ids': product.businessTypeIds,
    'attributes': product.attributes,
  };
}

/// Parsea el resultado de una importación masiva.
BulkImportResult bulkImportResultFromJson(Map<String, dynamic> json) {
  final rawErrors = (json['errors'] as List?) ?? [];
  final errors = rawErrors
      .cast<Map<String, dynamic>>()
      .map(_bulkImportErrorFromJson)
      .toList();

  return BulkImportResult(
    totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
    importedCount: (json['imported_count'] as num?)?.toInt() ?? 0,
    failedCount: (json['failed_count'] as num?)?.toInt() ?? errors.length,
    errors: errors,
  );
}

BulkImportError _bulkImportErrorFromJson(Map<String, dynamic> json) {
  return BulkImportError(
    rowNumber: (json['row_number'] as num?)?.toInt() ?? 0,
    sku: json['sku'] as String?,
    reason: (json['reason'] as String?) ?? 'Error desconocido',
  );
}

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

DateTime? _parseDateOrNull(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return null;
}
