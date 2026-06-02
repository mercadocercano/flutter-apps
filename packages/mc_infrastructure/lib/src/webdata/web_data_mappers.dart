import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del webdata-service ↔ entidades de dominio Web Data.

// ---------------------------------------------------------------------------
// WebDataDashboardStats
// ---------------------------------------------------------------------------

/// Formato esperado:
/// {"active_sources":N,"inactive_sources":N,"jobs_today":N,
///  "total_products":N,"success_rate":0.87}
WebDataDashboardStats dashboardStatsFromJson(Map<String, dynamic> json) {
  final data = json['stats'] as Map<String, dynamic>? ?? json;

  return WebDataDashboardStats(
    activeSources: (data['active_sources'] as num?)?.toInt() ?? 0,
    inactiveSources: (data['inactive_sources'] as num?)?.toInt() ?? 0,
    jobsToday: (data['jobs_today'] as num?)?.toInt() ?? 0,
    totalProducts: (data['total_products'] as num?)?.toInt() ?? 0,
    successRate: (data['success_rate'] as num?)?.toDouble() ?? 0.0,
  );
}

// ---------------------------------------------------------------------------
// WebSource
// ---------------------------------------------------------------------------

/// Formato esperado:
/// {"sources":[...],"pagination":{...}}
PaginatedResult<WebSource> paginatedSourcesFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['sources'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

  return PaginatedResult<WebSource>(
    items: rawItems.cast<Map<String, dynamic>>().map(webSourceFromJson).toList(),
    totalCount: (pagination['total'] as num?)?.toInt() ?? 0,
    page: (pagination['page'] as num?)?.toInt() ?? 1,
    pageSize: (pagination['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
  );
}

WebSource webSourceFromJson(Map<String, dynamic> json) {
  return WebSource(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    status: _parseSourceStatus(json['status'] as String? ?? 'inactive'),
    schedule: json['schedule'] as String?,
    businessTypeIds:
        ((json['business_type_ids'] as List?) ?? []).cast<String>(),
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );
}

Map<String, dynamic> webSourceToJson(WebSource source) {
  return <String, dynamic>{
    'name': source.name,
    'url': source.url,
    'status': source.status.name,
    if (source.schedule != null) 'schedule': source.schedule,
    'business_type_ids': source.businessTypeIds,
  };
}

WebSourceStatus _parseSourceStatus(String raw) {
  return WebSourceStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => WebSourceStatus.inactive,
  );
}

// ---------------------------------------------------------------------------
// WebJob
// ---------------------------------------------------------------------------

/// Formato esperado:
/// {"jobs":[...],"pagination":{...}}
PaginatedResult<WebJob> paginatedJobsFromJson(Map<String, dynamic> json) {
  final rawItems = (json['jobs'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

  return PaginatedResult<WebJob>(
    items: rawItems.cast<Map<String, dynamic>>().map(webJobFromJson).toList(),
    totalCount: (pagination['total'] as num?)?.toInt() ?? 0,
    page: (pagination['page'] as num?)?.toInt() ?? 1,
    pageSize: (pagination['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
  );
}

WebJob webJobFromJson(Map<String, dynamic> json) {
  final jobData = json['job'] as Map<String, dynamic>? ?? json;

  return WebJob(
    id: jobData['id'] as String,
    sourceId: jobData['source_id'] as String,
    status: _parseJobStatus(jobData['status'] as String? ?? 'running'),
    progress: (jobData['progress'] as num?)?.toDouble() ?? 0.0,
    productsFound: (jobData['products_found'] as num?)?.toInt() ?? 0,
    errorLog: jobData['error_log'] as String?,
    startedAt: _parseDate(jobData['started_at']),
    finishedAt: jobData['finished_at'] != null
        ? _parseDate(jobData['finished_at'])
        : null,
  );
}

WebJobStatus _parseJobStatus(String raw) {
  return WebJobStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => WebJobStatus.running,
  );
}

// ---------------------------------------------------------------------------
// WebProduct
// ---------------------------------------------------------------------------

/// Formato esperado:
/// {"products":[...],"pagination":{...}}
PaginatedResult<WebProduct> paginatedProductsFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['products'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

  return PaginatedResult<WebProduct>(
    items:
        rawItems.cast<Map<String, dynamic>>().map(webProductFromJson).toList(),
    totalCount: (pagination['total'] as num?)?.toInt() ?? 0,
    page: (pagination['page'] as num?)?.toInt() ?? 1,
    pageSize: (pagination['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
  );
}

WebProduct webProductFromJson(Map<String, dynamic> json) {
  final productData = json['product'] as Map<String, dynamic>? ?? json;

  final rawHistory =
      (productData['price_history'] as List?) ?? [];

  return WebProduct(
    id: productData['id'] as String,
    sourceId: productData['source_id'] as String,
    name: productData['name'] as String,
    price: (productData['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: productData['image_url'] as String?,
    url: productData['url'] as String,
    businessTypeId: productData['business_type_id'] as String?,
    scrapedAt: _parseDate(productData['scraped_at']),
    priceHistory: rawHistory
        .cast<Map<String, dynamic>>()
        .map(pricePointFromJson)
        .toList(),
  );
}

Map<String, dynamic> webProductToJson(WebProduct product) {
  return <String, dynamic>{
    'name': product.name,
    'price': product.price,
    if (product.imageUrl != null) 'image_url': product.imageUrl,
    'url': product.url,
    if (product.businessTypeId != null)
      'business_type_id': product.businessTypeId,
  };
}

// ---------------------------------------------------------------------------
// PricePoint
// ---------------------------------------------------------------------------

List<PricePoint> priceHistoryFromJson(Map<String, dynamic> json) {
  final raw = (json['price_history'] as List?) ?? [];
  return raw.cast<Map<String, dynamic>>().map(pricePointFromJson).toList();
}

PricePoint pricePointFromJson(Map<String, dynamic> json) {
  return PricePoint(
    date: _parseDate(json['date']),
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    variationPercent: (json['variation_percent'] as num?)?.toDouble(),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
