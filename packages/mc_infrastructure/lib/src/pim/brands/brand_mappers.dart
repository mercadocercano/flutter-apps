import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio MarketplaceBrand.

/// Parsea la lista de marcas del pim-service.
/// Formato real: {"brands": [...], "pagination": {"offset","limit","total","total_pages",...}}
PaginatedResult<MarketplaceBrand> paginatedBrandsFromJson(
  Map<String, dynamic> json,
) {
  final rawItems = (json['brands'] as List?) ?? [];
  final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
  final total = (pagination['total'] as num?)?.toInt() ?? 0;
  final limit = (pagination['limit'] as num?)?.toInt() ?? 10;
  final offset = (pagination['offset'] as num?)?.toInt() ?? 0;
  final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;
  final page = limit > 0 ? (offset ~/ limit) + 1 : 1;

  return PaginatedResult<MarketplaceBrand>(
    items: rawItems.cast<Map<String, dynamic>>().map(brandFromJson).toList(),
    totalCount: total,
    page: page,
    pageSize: limit,
    totalPages: totalPages,
  );
}

MarketplaceBrand brandFromJson(Map<String, dynamic> json) {
  return MarketplaceBrand(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: (json['slug'] as String?) ?? '',
    normalizedName: json['normalized_name'] as String?,
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    website: json['website'] as String?,
    verificationStatus: BrandVerificationStatus.fromString(
      json['verification_status'] as String?,
    ),
    qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
    productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    categoryTags: _toStringList(json['category_tags']),
    aliases: _toStringList(json['aliases']),
    sources: _toStringList(json['sources']),
    isActive: (json['is_active'] as bool?) ?? true,
    backgroundColor: json['background_color'] as String?,
    textColor: json['text_color'] as String?,
    typography: json['typography'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

List<String> _toStringList(dynamic value) {
  if (value is List) return value.cast<String>();
  return const [];
}
