/// Resultado de una operación de verificación/desverificación en lote.
class BulkVerifyResult {
  final String mode;
  final String? snapshotRef;
  final int totalRequested;
  final int processed;
  final int skipped;
  final int failed;

  const BulkVerifyResult({
    required this.mode,
    this.snapshotRef,
    required this.totalRequested,
    required this.processed,
    required this.skipped,
    required this.failed,
  });

  factory BulkVerifyResult.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return BulkVerifyResult(
      mode: json['mode'] as String? ?? '',
      snapshotRef: json['snapshot_ref'] as String?,
      totalRequested: summary['total_requested'] as int? ?? 0,
      processed: summary['processed'] as int? ?? 0,
      skipped: summary['skipped'] as int? ?? 0,
      failed: summary['failed'] as int? ?? 0,
    );
  }
}
