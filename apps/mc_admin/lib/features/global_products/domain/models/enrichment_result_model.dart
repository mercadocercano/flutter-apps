/// Resultado devuelto por POST /webdata/api/v1/enrichment/run
class EnrichmentResult {
  final int processed;
  final int skipped;
  final int failed;
  final int totalCostCents;
  final List<String> errors;

  const EnrichmentResult({
    required this.processed,
    required this.skipped,
    required this.failed,
    required this.totalCostCents,
    required this.errors,
  });

  factory EnrichmentResult.fromJson(Map<String, dynamic> json) {
    return EnrichmentResult(
      processed: json['processed'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      totalCostCents: json['total_cost_cents'] as int? ?? 0,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : const [],
    );
  }

  /// Costo formateado en pesos/dólares (cents → unidad mayor)
  String get formattedCost {
    final dollars = totalCostCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  bool get hasErrors => errors.isNotEmpty;
}
