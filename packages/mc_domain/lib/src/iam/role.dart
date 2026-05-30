import 'package:equatable/equatable.dart';

enum RoleType { system, tenant }

enum RoleStatus { active, inactive }

/// Entidad de dominio: Role.
/// Representa un rol de acceso, ya sea del sistema o de un tenant específico.
class Role extends Equatable {
  final String id;
  final String name;
  final String? description;
  final RoleType type;
  final String? tenantId;
  final List<String> permissions;
  final RoleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Role({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.tenantId,
    required this.permissions,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        tenantId,
        permissions,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Parámetros para crear o actualizar un rol.
class UpsertRoleParams {
  final String name;
  final String? description;
  final RoleType type;
  final String? tenantId;
  final List<String> permissions;
  final RoleStatus status;

  const UpsertRoleParams({
    required this.name,
    this.description,
    required this.type,
    this.tenantId,
    required this.permissions,
    required this.status,
  });
}
