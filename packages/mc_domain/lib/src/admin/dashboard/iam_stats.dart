import 'package:equatable/equatable.dart';

/// Value object con las métricas del módulo IAM para el dashboard.
///
/// Agrega contadores de tenants, roles y planes para dar una vista
/// de alto nivel del estado del marketplace desde el punto de vista
/// de identidad y acceso.
class IamStats extends Equatable {
  final int activeTenants;
  final int newTenantsLast24h;
  final int totalRoles;
  final int totalPlans;

  const IamStats({
    required this.activeTenants,
    required this.newTenantsLast24h,
    required this.totalRoles,
    required this.totalPlans,
  });

  @override
  List<Object?> get props => [
        activeTenants,
        newTenantsLast24h,
        totalRoles,
        totalPlans,
      ];
}
