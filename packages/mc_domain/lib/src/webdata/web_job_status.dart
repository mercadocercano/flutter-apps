/// Estado de un job de scraping.
enum WebJobStatus {
  /// El job está en ejecución actualmente.
  running,

  /// El job finalizó correctamente.
  completed,

  /// El job terminó con error.
  failed,

  /// El job fue cancelado manualmente.
  cancelled,
}
