import 'package:equatable/equatable.dart';

enum PlanType { free, starter, professional, enterprise }

enum PlanStatus { active, inactive }

/// Entidad de dominio: Plan.
/// Representa un plan de suscripción para tenants.
class Plan extends Equatable {
  final String id;
  final String name;
  final String? description;
  final PlanType type;
  final double price;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> limits;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plan({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.price,
    required this.currency,
    required this.features,
    required this.limits,
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
        price,
        currency,
        features,
        limits,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Parámetros para crear o actualizar un plan.
class UpsertPlanParams {
  final String name;
  final String? description;
  final PlanType type;
  final double price;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> limits;
  final PlanStatus status;

  const UpsertPlanParams({
    required this.name,
    this.description,
    required this.type,
    required this.price,
    required this.currency,
    required this.features,
    required this.limits,
    required this.status,
  });
}
