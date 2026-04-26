/// GlobalProduct domain model — catálogo global de productos del marketplace
class GlobalProduct {
  final String id;
  final String? ean;
  final String name;
  final String? description;
  final String? brand;
  final String? category;
  final double? price;
  final String? imageUrl;
  final List<String> imageUrls;
  final String source;
  final String? sourceUrl;
  final double reliability;
  final int qualityScore;
  final bool isVerified;
  final bool isActive;
  final String? businessType;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GlobalProduct({
    required this.id,
    this.ean,
    required this.name,
    this.description,
    this.brand,
    this.category,
    this.price,
    this.imageUrl,
    this.imageUrls = const [],
    required this.source,
    this.sourceUrl,
    required this.reliability,
    required this.qualityScore,
    required this.isVerified,
    required this.isActive,
    this.businessType,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlobalProduct.fromJson(Map<String, dynamic> json) {
    String? toNullable(dynamic v) {
      final s = v?.toString();
      return (s == null || s.isEmpty) ? null : s;
    }

    return GlobalProduct(
      id: json['id'] as String,
      ean: toNullable(json['ean']),
      name: json['name'] as String,
      description: toNullable(json['description']),
      brand: toNullable(json['brand']),
      category: toNullable(json['category']),
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: toNullable(json['image_url']),
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : const [],
      source: json['source'] as String,
      sourceUrl: toNullable(json['source_url']),
      reliability: (json['reliability'] as num).toDouble(),
      qualityScore: json['quality_score'] as int,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      businessType: toNullable(json['business_type']),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ean': ean,
      'name': name,
      'description': description,
      'brand': brand,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'source': source,
      'source_url': sourceUrl,
      'reliability': reliability,
      'quality_score': qualityScore,
      'is_verified': isVerified,
      'is_active': isActive,
      'business_type': businessType,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalProduct copyWith({
    String? id,
    String? ean,
    String? name,
    String? description,
    String? brand,
    String? category,
    double? price,
    String? imageUrl,
    List<String>? imageUrls,
    String? source,
    String? sourceUrl,
    double? reliability,
    int? qualityScore,
    bool? isVerified,
    bool? isActive,
    String? businessType,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalProduct(
      id: id ?? this.id,
      ean: ean ?? this.ean,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      reliability: reliability ?? this.reliability,
      qualityScore: qualityScore ?? this.qualityScore,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      businessType: businessType ?? this.businessType,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static GlobalProduct empty() {
    return GlobalProduct(
      id: '',
      name: '',
      source: '',
      reliability: 0,
      qualityScore: 0,
      isVerified: false,
      isActive: false,
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    );
  }
}

/// Página paginada de productos globales
class GlobalProductsPage {
  final List<GlobalProduct> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const GlobalProductsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory GlobalProductsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return GlobalProductsPage(
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(GlobalProduct.fromJson)
          .toList(),
      totalCount: json['total_count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 50,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
