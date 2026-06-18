import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del webdata-service ↔ entidades de dominio Web Data.

// ---------------------------------------------------------------------------
// WebDataDashboardStats
// ---------------------------------------------------------------------------

/// Formato real del backend:
/// {"data":{"total_sources":N,"active_sources":N,"total_jobs":N,
///           "pending_jobs":N,"running_jobs":N,"completed_jobs":N,
///           "failed_jobs":N,"total_products":N}}
/// No devuelve "inactive_sources", "jobs_today" ni "success_rate" directamente.
WebDataDashboardStats dashboardStatsFromJson(Map<String, dynamic> json) {
  // Backend wraps stats in "data"; old code expected "stats" or flat — tolerate all.
  final data = json['data'] as Map<String, dynamic>?
      ?? json['stats'] as Map<String, dynamic>?
      ?? json;

  final activeSources = (data['active_sources'] as num?)?.toInt() ?? 0;
  final totalSources = (data['total_sources'] as num?)?.toInt() ?? 0;
  // "inactive_sources" no existe — se deriva de total - active.
  final inactiveSources = totalSources - activeSources;

  final completedJobs = (data['completed_jobs'] as num?)?.toInt() ?? 0;
  final failedJobs = (data['failed_jobs'] as num?)?.toInt() ?? 0;
  final totalJobs = (data['total_jobs'] as num?)?.toInt() ?? 0;
  // "jobs_today" no existe — se usa total_jobs como aproximación.
  final jobsToday = (data['jobs_today'] as num?)?.toInt() ?? totalJobs;
  // "success_rate" no existe — se calcula de completed/(completed+failed).
  final double successRate;
  if (data.containsKey('success_rate')) {
    successRate = (data['success_rate'] as num?)?.toDouble() ?? 0.0;
  } else {
    final denominator = completedJobs + failedJobs;
    successRate = denominator > 0 ? completedJobs / denominator : 0.0;
  }

  return WebDataDashboardStats(
    activeSources: activeSources,
    inactiveSources: inactiveSources.clamp(0, double.maxFinite.toInt()),
    jobsToday: jobsToday,
    totalProducts: (data['total_products'] as num?)?.toInt() ?? 0,
    successRate: successRate,
  );
}

// ---------------------------------------------------------------------------
// WebSource
// ---------------------------------------------------------------------------

/// Formato real del backend:
/// {"data":[...],"meta":{"page":N,"page_size":N,"total":N,"total_pages":N}}
/// (antes se esperaba {"sources":[...],"pagination":{...}})
PaginatedResult<WebSource> paginatedSourcesFromJson(
  Map<String, dynamic> json,
) {
  // Backend wraps list in "data"; old code expected "sources" — tolerate both.
  final rawItems = (json['data'] as List?) ?? (json['sources'] as List?) ?? [];

  // Backend uses "meta" sub-object; old code expected "pagination".
  final meta = json['meta'] as Map<String, dynamic>?
      ?? json['pagination'] as Map<String, dynamic>?
      ?? {};

  return PaginatedResult<WebSource>(
    items: rawItems.cast<Map<String, dynamic>>().map(webSourceFromJson).toList(),
    totalCount: (meta['total'] as num?)?.toInt() ?? 0,
    page: (meta['page'] as num?)?.toInt() ?? 1,
    pageSize: (meta['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
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

/// Formato real del backend:
/// {"data":[...],"meta":{"page":N,"page_size":N,"total":N,"total_pages":N}}
/// (antes se esperaba {"jobs":[...],"pagination":{...}})
PaginatedResult<WebJob> paginatedJobsFromJson(Map<String, dynamic> json) {
  // Backend wraps list in "data"; old code expected "jobs" — tolerate both.
  final rawItems = (json['data'] as List?) ?? (json['jobs'] as List?) ?? [];

  // Backend uses "meta" sub-object; old code expected "pagination".
  final meta = json['meta'] as Map<String, dynamic>?
      ?? json['pagination'] as Map<String, dynamic>?
      ?? {};

  return PaginatedResult<WebJob>(
    items: rawItems.cast<Map<String, dynamic>>().map(webJobFromJson).toList(),
    totalCount: (meta['total'] as num?)?.toInt() ?? 0,
    page: (meta['page'] as num?)?.toInt() ?? 1,
    pageSize: (meta['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
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

/// Formato real del backend:
/// {"data":[...],"meta":{"page":N,"page_size":N,"total":N,"total_pages":N}}
/// (antes se esperaba {"products":[...],"pagination":{...}})
PaginatedResult<WebProduct> paginatedProductsFromJson(
  Map<String, dynamic> json,
) {
  // Backend wraps list in "data"; old code expected "products" — tolerate both.
  final rawItems = (json['data'] as List?) ?? (json['products'] as List?) ?? [];

  // Backend uses "meta" sub-object; old code expected "pagination".
  final meta = json['meta'] as Map<String, dynamic>?
      ?? json['pagination'] as Map<String, dynamic>?
      ?? {};

  return PaginatedResult<WebProduct>(
    items:
        rawItems.cast<Map<String, dynamic>>().map(webProductFromJson).toList(),
    totalCount: (meta['total'] as num?)?.toInt() ?? 0,
    page: (meta['page'] as num?)?.toInt() ?? 1,
    pageSize: (meta['page_size'] as num?)?.toInt() ?? 20,
    totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
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
