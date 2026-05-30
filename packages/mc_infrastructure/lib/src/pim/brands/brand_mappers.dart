import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON del pim-service → entidades de dominio MarketplaceBrand.

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
