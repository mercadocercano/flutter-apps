import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio GlobalProduct / BulkImportResult.

/// Parsea lista paginada de productos globales.
/// Formato real del backend:
/// {"items":[...],"total_count":N,"page":N,"page_size":N,"total_pages":N}
/// (sin sub-objeto "pagination"; "products" era el formato anterior)
PaginatedResult<GlobalProduct> paginatedGlobalProductsFromJson(
  Map<String, dynamic> json,
) {
  // Backend returns "items"; old code expected "products" — tolerate both.
  final rawItems = (json['items'] as List?) ?? (json['products'] as List?) ?? [];

  // Backend uses flat pagination keys (no "pagination" sub-object).
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
  final total = ((json['total_count'] ?? pagination['total']) as num?)?.toInt() ?? 0;
  final page = ((json['page'] ?? pagination['page']) as num?)?.toInt() ?? 1;
  final pageSize = ((json['page_size'] ?? pagination['page_size']) as num?)?.toInt() ?? 20;
  final totalPages = ((json['total_pages'] ?? pagination['total_pages']) as num?)?.toInt() ?? 1;

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
/// El backend devuelve campos distintos al modelo original:
///   - "ean" en lugar de "sku"
///   - "brand" (string) en lugar de "business_type_ids" (lista)
///   - "business_type" (string) en lugar de "business_type_ids"
///   - "category" (string path) en lugar de "category_id"
///   - "metadata" en lugar de "attributes"
GlobalProduct globalProductFromJson(Map<String, dynamic> json) {
  // sku: backend usa "ean"; tolera también "sku" legacy.
  final sku = ((json['ean'] ?? json['sku']) as String?) ?? '';

  // business_type_ids: backend devuelve "business_type" (string singular).
  // Lo encapsulamos en lista para mantener el contrato del dominio.
  final rawBusinessTypeIds = json['business_type_ids'] as List?;
  final businessTypeStr = json['business_type'] as String?;
  final List<String> businessTypeIds;
  if (rawBusinessTypeIds != null) {
    businessTypeIds = rawBusinessTypeIds.cast<String>();
  } else if (businessTypeStr != null && businessTypeStr.isNotEmpty) {
    businessTypeIds = [businessTypeStr];
  } else {
    businessTypeIds = const [];
  }

  // attributes: backend usa "metadata"; tolera "attributes" legacy.
  final rawAttributes =
      (json['attributes'] as Map<String, dynamic>?) ??
      (json['metadata'] as Map<String, dynamic>?) ??
      const {};

  return GlobalProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: sku,
    barcode: json['barcode'] as String?,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    businessTypeIds: businessTypeIds,
    // category_id: backend devuelve "category" (string path), no un UUID.
    // Lo guardamos como null si no es un UUID, para no romper FK esperados.
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
