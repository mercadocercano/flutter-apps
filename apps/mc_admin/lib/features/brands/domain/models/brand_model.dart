/// Brand domain model
class Brand {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? website;
  final List<String> aliases;
  final List<String> categoryTags;
  final double? qualityScore;
  final bool verificationStatus;
  final bool isActive;
  final String? backgroundColor;
  final String? textColor;
  final String? typography;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.website,
    this.aliases = const [],
    this.categoryTags = const [],
    this.qualityScore,
    this.verificationStatus = false,
    this.isActive = true,
    this.backgroundColor,
    this.textColor,
    this.typography,
    this.createdAt,
    this.updatedAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    String? _str(dynamic v) {
      final s = v?.toString();
      return (s == null || s.isEmpty) ? null : s;
    }

    return Brand(
      id: json['id'] as String,
      name: json['name'] as String,
      description: _str(json['description']),
      logoUrl: _str(json['logo_url']),
      website: _str(json['website']),
      aliases: List<String>.from(json['aliases'] ?? []),
      categoryTags: List<String>.from(json['category_tags'] ?? []),
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      verificationStatus: json['verification_status'] == 'verified' || json['verification_status'] == true,
      isActive: json['is_active'] as bool? ?? true,
      backgroundColor: _str(json['background_color']),
      textColor: _str(json['text_color']),
      typography: _str(json['typography']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'website': website,
      'aliases': aliases,
      'category_tags': categoryTags,
      'quality_score': qualityScore,
      'verification_status': verificationStatus,
      'is_active': isActive,
      'background_color': backgroundColor,
      'text_color': textColor,
      'typography': typography,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Brand copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? website,
    List<String>? aliases,
    List<String>? categoryTags,
    double? qualityScore,
    bool? verificationStatus,
    bool? isActive,
    String? backgroundColor,
    String? textColor,
    String? typography,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      aliases: aliases ?? this.aliases,
      categoryTags: categoryTags ?? this.categoryTags,
      qualityScore: qualityScore ?? this.qualityScore,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      typography: typography ?? this.typography,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Brand empty() {
    return const Brand(
      id: '',
      name: '',
    );
  }
}