import 'package:equatable/equatable.dart';

enum TenantStatus { active, inactive, suspended, deleted }

enum TenantType { personal, startup, business, enterprise }

/// Entidad de dominio: Tenant.
/// Representa a un comercio/organización dentro del sistema multi-tenant.
class Tenant extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final TenantType type;
  final TenantStatus status;
  final String ownerId;
  final String? domain;
  final String? planId;
  final int userCount;
  final int maxUsers;
  final Map<String, dynamic> settings;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.type,
    required this.status,
    required this.ownerId,
    this.domain,
    this.planId,
    this.userCount = 0,
    this.maxUsers = 0,
    required this.settings,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        type,
        status,
        ownerId,
        domain,
        planId,
        userCount,
        maxUsers,
        settings,
        expiresAt,
        createdAt,
        updatedAt,
        isActive,
      ];
}

/// Parámetros para crear un nuevo tenant.
class CreateTenantParams {
  final String name;
  final String slug;
  final TenantType type;
  final String ownerId;
  final String? description;
  final String? domain;

  const CreateTenantParams({
    required this.name,
    required this.slug,
    required this.type,
    required this.ownerId,
    this.description,
    this.domain,
  });
}

/// Parámetros para actualizar un tenant existente.
class UpdateTenantParams {
  final String? name;
  final String? description;
  final String? domain;
  final TenantStatus? status;
  final TenantType? type;
  final Map<String, dynamic>? settings;

  const UpdateTenantParams({
    this.name,
    this.description,
    this.domain,
    this.status,
    this.type,
    this.settings,
  });
}
