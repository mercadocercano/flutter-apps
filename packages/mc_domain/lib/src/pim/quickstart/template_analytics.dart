import 'package:equatable/equatable.dart';

/// Value object con métricas de uso de un BusinessTypeTemplate.
///
/// Registra cuántos tenants activaron el template, la fecha de última
/// activación y la tasa de completitud del catálogo generado.
class TemplateAnalytics extends Equatable {
  final String templateId;
  final int tenantsCount;
  final DateTime? lastActivatedAt;
  final double completionRate;

  const TemplateAnalytics({
    required this.templateId,
    required this.tenantsCount,
    this.lastActivatedAt,
    required this.completionRate,
  });

  /// Indica si el template fue usado al menos una vez.
  bool get hasBeenUsed => tenantsCount > 0;

  /// Indica si la tasa de completitud es aceptable (>= 50%).
  bool get isCompletionAcceptable => completionRate >= 0.5;

  @override
  List<Object?> get props => [
        templateId,
        tenantsCount,
        lastActivatedAt,
        completionRate,
      ];
}
