/// Estado operativo de un servicio del marketplace.
enum ServiceStatus {
  /// El servicio responde correctamente y dentro del umbral de latencia.
  online,

  /// El servicio responde pero con latencia alta o errores parciales.
  degraded,

  /// El servicio no responde o retorna errores críticos.
  offline,
}
