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
  return Tenant(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    description: json['description'] as String?,
    type: tenantTypeFromString(json['type'] as String?),
    status: tenantStatusFromString(json['status'] as String?),
    ownerId: json['owner_id'] as String,
    domain: json['domain'] as String?,
    planId: json['plan_id'] as String?,
    userCount: (json['user_count'] as num?)?.toInt() ?? 0,
    maxUsers: (json['max_users'] as num?)?.toInt() ?? 0,
    settings: (json['settings'] as Map<String, dynamic>?) ?? {},
    expiresAt: json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    isActive: (json['is_active'] as bool?) ?? false,
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
  final rawPerms = json['permissions'];
  final permissions = rawPerms is List
      ? rawPerms.cast<String>()
      : <String>[];

  return Role(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    type: roleTypeFromString(json['type'] as String?),
    tenantId: json['tenant_id'] as String?,
    permissions: permissions,
    status: roleStatusFromString(json['status'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
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
  final rawFeatures = json['features'];
  final features = rawFeatures is List
      ? rawFeatures.cast<String>()
      : <String>[];

  return Plan(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    type: planTypeFromString(json['type'] as String?),
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    currency: (json['currency'] as String?) ?? 'ARS',
    features: features,
    limits: (json['limits'] as Map<String, dynamic>?) ?? {},
    status: planStatusFromString(json['status'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
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
