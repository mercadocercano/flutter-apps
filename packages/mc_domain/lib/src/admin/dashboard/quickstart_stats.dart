import 'package:equatable/equatable.dart';

/// Value object con las métricas del módulo Quickstart para el dashboard.
///
/// Agrega contadores de tipos de negocio y templates activos para dar
/// visibilidad del estado del onboarding de nuevos tenants.
class QuickstartStats extends Equatable {
  final int activeBusinessTypes;
  final int activeTemplates;

  const QuickstartStats({
    required this.activeBusinessTypes,
    required this.activeTemplates,
  });

  @override
  List<Object?> get props => [activeBusinessTypes, activeTemplates];
}
