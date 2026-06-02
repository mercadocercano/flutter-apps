/// Estado de una fuente de datos web (scraping).
enum WebSourceStatus {
  /// La fuente está activa y puede ejecutarse según su schedule.
  active,

  /// La fuente está desactivada y no se ejecutará automáticamente.
  inactive,

  /// La fuente tiene un job en ejecución actualmente.
  running,

  /// La última ejecución de la fuente terminó con error.
  error,
}
