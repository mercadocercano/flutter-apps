import 'package:mc_domain/mc_domain.dart';

/// Mappers: JSON raw del IAM → entidades de dominio.

TenantStatus tenantStatusFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'ACTIVE' => TenantStatus.active,
    'INACTIVE' => TenantStatus.inactive,
    'SUSPENDED' => TenantStatus.suspended,
    'DELETED' => TenantStatus.deleted,
    _ => TenantStatus.inactive,
  };
}

String tenantStatusToString(TenantStatus status) {
  return switch (status) {
    TenantStatus.active => 'ACTIVE',
    TenantStatus.inactive => 'INACTIVE',
    TenantStatus.suspended => 'SUSPENDED',
    TenantStatus.deleted => 'DELETED',
  };
}

TenantType tenantTypeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'PERSONAL' => TenantType.personal,
    'STARTUP' => TenantType.startup,
    'BUSINESS' => TenantType.business,
    'ENTERPRISE' => TenantType.enterprise,
    _ => TenantType.personal,
  };
}

String tenantTypeToString(TenantType type) {
  return switch (type) {
    TenantType.personal => 'PERSONAL',
    TenantType.startup => 'STARTUP',
    TenantType.business => 'BUSINESS',
    TenantType.enterprise => 'ENTERPRISE',
  };
}

Tenant tenantFromJson(Map<String, dynamic> json) {
  // List endpoint returns PascalCase (Go struct without json tags).
  // Support both PascalCase and snake_case for every field.
  final status = tenantStatusFromString(
    ((json['status'] ?? json['Status']) as String?),
  );
  return Tenant(
    id: ((json['id'] ?? json['ID']) as String),
    name: ((json['name'] ?? json['Name']) as String),
    slug: ((json['slug'] ?? json['Slug']) as String),
    description: (json['description'] ?? json['Description']) as String?,
    type: tenantTypeFromString(
      ((json['type'] ?? json['Type']) as String?),
    ),
    status: status,
    ownerId: ((json['owner_id'] ?? json['OwnerID']) as String),
    domain: (json['domain'] ?? json['Domain']) as String?,
    planId: (json['plan_id'] ?? json['PlanID']) as String?,
    userCount: ((json['user_count'] ?? json['UserCount']) as num?)?.toInt() ?? 0,
    maxUsers: ((json['max_users'] ?? json['MaxUsers']) as num?)?.toInt() ?? 0,
    settings: (json['settings'] ?? json['Settings']) is Map<String, dynamic>
        ? (json['settings'] ?? json['Settings']) as Map<String, dynamic>
        : {},
    expiresAt: _parseDateOrNull(json['expires_at'] ?? json['ExpiresAt']),
    createdAt: _parseDate(json['created_at'] ?? json['CreatedAt']),
    updatedAt: _parseDate(json['updated_at'] ?? json['UpdatedAt']),
    isActive: (json['is_active'] as bool?) ?? (status == TenantStatus.active),
  );
}

// --- Role mappers ---

RoleStatus roleStatusFromString(String? value) {
  return switch (value?.toLowerCase()) {
    'active' => RoleStatus.active,
    'inactive' => RoleStatus.inactive,
    _ => RoleStatus.inactive,
  };
}

String roleStatusToString(RoleStatus status) {
  return switch (status) {
    RoleStatus.active => 'active',
    RoleStatus.inactive => 'inactive',
  };
}

RoleType roleTypeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'SYSTEM' => RoleType.system,
    'TENANT' => RoleType.tenant,
    // Backend may return 'CUSTOM' for non-system roles created per-tenant
    'CUSTOM' => RoleType.tenant,
    _ => RoleType.system,
  };
}

String roleTypeToString(RoleType type) {
  return switch (type) {
    RoleType.system => 'SYSTEM',
    RoleType.tenant => 'TENANT',
  };
}

Role roleFromJson(Map<String, dynamic> json) {
  // List endpoint returns PascalCase (Go struct without json tags),
  // detail endpoint returns snake_case. Support both.
  final rawPerms = json['permissions'] ?? json['Permissions'];
  final permissions = rawPerms is List
      ? rawPerms.cast<String>()
      : <String>[];

  // List uses IsActive (bool), detail uses status string.
  // Map IsActive → RoleStatus; fall back to 'status' field.
  final RoleStatus status;
  final isActiveBool = json['IsActive'];
  if (isActiveBool is bool) {
    status = isActiveBool ? RoleStatus.active : RoleStatus.inactive;
  } else {
    status = roleStatusFromString(json['status'] as String?);
  }

  return Role(
    id: (json['id'] ?? json['ID']) as String,
    name: (json['name'] ?? json['Name']) as String,
    description: (json['description'] ?? json['Description']) as String?,
    type: roleTypeFromString(
      ((json['type'] ?? json['Type']) as String?),
    ),
    tenantId: (json['tenant_id'] ?? json['TenantID']) as String?,
    permissions: permissions,
    status: status,
    createdAt: _parseDate(json['created_at'] ?? json['CreatedAt']),
    updatedAt: _parseDate(json['updated_at'] ?? json['UpdatedAt']),
  );
}

// --- Plan mappers ---

PlanStatus planStatusFromString(String? value) {
  return switch (value?.toLowerCase()) {
    'active' => PlanStatus.active,
    'inactive' => PlanStatus.inactive,
    _ => PlanStatus.inactive,
  };
}

String planStatusToString(PlanStatus status) {
  return switch (status) {
    PlanStatus.active => 'active',
    PlanStatus.inactive => 'inactive',
  };
}

PlanType planTypeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'FREE' => PlanType.free,
    'STARTER' => PlanType.starter,
    'PROFESSIONAL' => PlanType.professional,
    'ENTERPRISE' => PlanType.enterprise,
    _ => PlanType.free,
  };
}

String planTypeToString(PlanType type) {
  return switch (type) {
    PlanType.free => 'FREE',
    PlanType.starter => 'STARTER',
    PlanType.professional => 'PROFESSIONAL',
    PlanType.enterprise => 'ENTERPRISE',
  };
}

Plan planFromJson(Map<String, dynamic> json) {
  // List endpoint returns PascalCase (Go struct without json tags),
  // detail endpoint returns snake_case. Support both.
  // Backend has price_month/PriceMonth and price_year/PriceYear, no single 'price' or 'currency' or 'limits'.
  final rawFeatures = json['features'] ?? json['Features'];
  final features = rawFeatures is List
      ? rawFeatures.cast<String>()
      : <String>[];

  // Use price_month as the canonical price field; fallback chain covers both cases.
  final rawPrice = json['price_month'] ?? json['PriceMonth'] ?? json['price'];
  final price = (rawPrice as num?)?.toDouble() ?? 0.0;

  return Plan(
    id: ((json['id'] ?? json['ID']) as String),
    name: ((json['name'] ?? json['Name']) as String),
    description: (json['description'] ?? json['Description']) as String?,
    type: planTypeFromString(
      ((json['type'] ?? json['Type']) as String?),
    ),
    price: price,
    currency: (json['currency'] as String?) ?? 'ARS',
    features: features,
    limits: (json['limits'] as Map<String, dynamic>?) ?? {},
    status: planStatusFromString(
      ((json['status'] ?? json['Status']) as String?),
    ),
    createdAt: _parseDate(json['created_at'] ?? json['CreatedAt']),
    updatedAt: _parseDate(json['updated_at'] ?? json['UpdatedAt']),
  );
}

PaginatedResult<T> paginatedFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromItem,
) {
  final rawItems = json['items'] as List? ?? [];
  return PaginatedResult<T>(
    items: rawItems.cast<Map<String, dynamic>>().map(fromItem).toList(),
    totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['page_size'] as num?)?.toInt() ?? 10,
    totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
  );
}

// Parseo de fechas tolerante: si el backend omite o manda null el timestamp,
// no se rompe la lista entera (cae a now() en vez de lanzar TypeError).
DateTime _parseDate(dynamic v) =>
    v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();

DateTime? _parseDateOrNull(dynamic v) =>
    v is String ? DateTime.tryParse(v) : null;
