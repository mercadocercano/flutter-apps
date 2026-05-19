/// Typed model for a quickstart template.
/// Handles both legacy seed format and new entity format field names.
class BusinessTypeTemplate {
  final String id;
  final String businessTypeId;
  final String name;
  final String description;
  final String version;
  final String region;
  final bool isDefault;
  final bool isActive;
  final List<CategoryTemplateItem> categories;
  final List<BrandTemplateItem> brands;
  final List<ProductTemplateItem> products;

  const BusinessTypeTemplate({
    required this.id,
    required this.businessTypeId,
    required this.name,
    required this.description,
    required this.version,
    required this.region,
    required this.isDefault,
    required this.isActive,
    required this.categories,
    required this.brands,
    required this.products,
  });

  factory BusinessTypeTemplate.fromJson(Map<String, dynamic> json) {
    return BusinessTypeTemplate(
      id: json['id'] as String? ?? '',
      businessTypeId: json['business_type_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
      region: json['region'] as String? ?? 'AR',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      categories: (json['categories'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(CategoryTemplateItem.fromJson)
          .toList(),
      brands: (json['brands'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(BrandTemplateItem.fromJson)
          .toList(),
      products: (json['products'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProductTemplateItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'version': version,
        'region': region,
        'is_default': isDefault,
        'is_active': isActive,
        'attributes': [],
        'metadata': {},
        'categories': categories.map((c) => c.toJson()).toList(),
        'brands': brands.map((b) => b.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList(),
      };

  BusinessTypeTemplate copyWith({
    List<CategoryTemplateItem>? categories,
    List<BrandTemplateItem>? brands,
    List<ProductTemplateItem>? products,
    String? name,
    String? version,
  }) {
    return BusinessTypeTemplate(
      id: id,
      businessTypeId: businessTypeId,
      name: name ?? this.name,
      description: description,
      version: version ?? this.version,
      region: region,
      isDefault: isDefault,
      isActive: isActive,
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      products: products ?? this.products,
    );
  }
}

class CategoryTemplateItem {
  final String id;
  final String name;
  final String slug;
  final int level;
  final String? parentSlug;

  const CategoryTemplateItem({
    this.id = '',
    required this.name,
    required this.slug,
    required this.level,
    this.parentSlug,
  });

  factory CategoryTemplateItem.fromJson(Map<String, dynamic> json) {
    return CategoryTemplateItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      parentSlug: json['parent_slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'level': level,
        if (parentSlug != null && parentSlug!.isNotEmpty) 'parent_slug': parentSlug,
      };
}

class BrandTemplateItem {
  final String name;
  final List<String> suggestedForCategories;

  const BrandTemplateItem({
    required this.name,
    this.suggestedForCategories = const [],
  });

  factory BrandTemplateItem.fromJson(Map<String, dynamic> json) {
    return BrandTemplateItem(
      name: json['name'] as String? ?? '',
      suggestedForCategories:
          (json['suggested_for_categories'] as List? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (suggestedForCategories.isNotEmpty)
          'suggested_for_categories': suggestedForCategories,
      };
}

class ProductTemplateItem {
  final String name;
  final String? brand;
  final String? categorySlug;
  final String? imageUrl;
  final double? priceReference;
  final String? unit;

  const ProductTemplateItem({
    required this.name,
    this.brand,
    this.categorySlug,
    this.imageUrl,
    this.priceReference,
    this.unit,
  });

  factory ProductTemplateItem.fromJson(Map<String, dynamic> json) {
    // Handle both legacy format (category_slug, price_reference, brand)
    // and new entity format (category_id, price, brand_name)
    final price = (json['price_reference'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble();
    final brand = json['brand'] as String? ??
        json['brand_name'] as String?;
    final categorySlug = json['category_slug'] as String? ??
        json['category_id'] as String?;

    return ProductTemplateItem(
      name: json['name'] as String? ?? '',
      brand: (brand?.isNotEmpty == true) ? brand : null,
      categorySlug: (categorySlug?.isNotEmpty == true) ? categorySlug : null,
      imageUrl: json['image_url'] as String?,
      priceReference: (price != null && price > 0) ? price : null,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category_id': categorySlug ?? '',
        'category_slug': categorySlug ?? '',
        if (brand != null) 'brand': brand,
        if (brand != null) 'brand_name': brand,
        'sku': '',
        'price': priceReference ?? 0.0,
        if (priceReference != null) 'price_reference': priceReference,
        if (imageUrl != null) 'image_url': imageUrl,
        if (unit != null) 'unit': unit,
      };
}
