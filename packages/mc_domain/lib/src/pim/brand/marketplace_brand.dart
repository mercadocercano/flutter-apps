import 'package:equatable/equatable.dart';

/// Estado de verificación de una marca en el marketplace.
enum BrandVerificationStatus {
  verified,
  unverified,
  pending;

  static BrandVerificationStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'verified' => BrandVerificationStatus.verified,
      'pending' => BrandVerificationStatus.pending,
      _ => BrandVerificationStatus.unverified,
    };
  }

  String toApiString() => name;
}

/// Entidad de marca del marketplace — administrada por el admin.
/// Distinta de Brand (dominio POS) que es más simple.
class MarketplaceBrand extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? normalizedName;
  final String? description;
  final String? logoUrl;
  final String? website;
  final BrandVerificationStatus verificationStatus;
  final double qualityScore;
  final int productCount;
  final List<String> categoryTags;
  final List<String> aliases;
  final List<String> sources;
  final bool isActive;
  final String? backgroundColor;
  final String? textColor;
  final String? typography;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketplaceBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.normalizedName,
    this.description,
    this.logoUrl,
    this.website,
    this.verificationStatus = BrandVerificationStatus.unverified,
    this.qualityScore = 0.0,
    this.productCount = 0,
    this.categoryTags = const [],
    this.aliases = const [],
    this.sources = const [],
    this.isActive = true,
    this.backgroundColor,
    this.textColor,
    this.typography,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => verificationStatus == BrandVerificationStatus.verified;

  MarketplaceBrand copyWith({
    String? id,
    String? name,
    String? slug,
    String? normalizedName,
    String? description,
    String? logoUrl,
    String? website,
    BrandVerificationStatus? verificationStatus,
    double? qualityScore,
    int? productCount,
    List<String>? categoryTags,
    List<String>? aliases,
    List<String>? sources,
    bool? isActive,
    String? backgroundColor,
    String? textColor,
    String? typography,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceBrand(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      normalizedName: normalizedName ?? this.normalizedName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      qualityScore: qualityScore ?? this.qualityScore,
      productCount: productCount ?? this.productCount,
      categoryTags: categoryTags ?? this.categoryTags,
      aliases: aliases ?? this.aliases,
      sources: sources ?? this.sources,
      isActive: isActive ?? this.isActive,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      typography: typography ?? this.typography,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        normalizedName,
        description,
        logoUrl,
        website,
        verificationStatus,
        qualityScore,
        productCount,
        categoryTags,
        aliases,
        sources,
        isActive,
        backgroundColor,
        textColor,
        typography,
        createdAt,
        updatedAt,
      ];
}
