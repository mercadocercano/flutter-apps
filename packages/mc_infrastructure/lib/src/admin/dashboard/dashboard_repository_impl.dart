import 'dart:async';

import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';

/// Implementación HTTP de [DashboardRepository].
///
/// Compone estadísticas de múltiples endpoints vía Kong en paralelo.
/// Cada sección aísla sus errores: si un endpoint falla, retorna null
/// para esa sección sin bloquear el resto del dashboard.
///
/// Rutas (todas a nivel de plataforma — el dashboard es una vista de
/// marketplace admin, NO de un tenant particular):
/// - IAM: /iam/api/v1/tenants, /iam/api/v1/roles, /iam/api/v1/plans
/// - PIM: /pim/api/v1/marketplace/overview (un solo endpoint agregado)
/// - WebData: /webdata/api/v1/stats (auth por API-Key de marketplace admin)
/// - Quickstart: /pim/api/v1/business-types, /pim/api/v1/quickstart/templates
/// - Health: pings a cada servicio midiendo latencia con Stopwatch
class DashboardRepositoryImpl implements DashboardRepository {
  static const _iam = '/iam/api/v1';
  static const _pim = '/pim/api/v1';
  static const _webdata = '/webdata/api/v1';

  static const _degradedLatencyMs = 1000;

  /// API-Key de marketplace admin para los endpoints de webdata que validan
  /// por `X-API-Key` (modo plataforma → tenant "global"). Configurable en
  /// build con --dart-define; default = la clave de desarrollo del backend.
  static const _marketplaceAdminApiKey = String.fromEnvironment(
    'MARKETPLACE_ADMIN_API_KEY',
    defaultValue: 'marketplace-admin-key-2025',
  );

  final KongClient _client;

  DashboardRepositoryImpl(this._client);

  // ─── DashboardRepository ──────────────────────────────────────────────────

  @override
  Future<DashboardStats> getDashboardStats() async {
    final results = await Future.wait([
      _fetchIamStats(),
      _fetchPimStats(),
      _fetchWebDataStats(),
      _fetchQuickstartStats(),
      getServicesHealth(),
    ]);

    return DashboardStats(
      iam: results[0] as IamStats?,
      pim: results[1] as PimStats?,
      webData: results[2] as WebDataStats?,
      quickstart: results[3] as QuickstartStats?,
      services: results[4] as List<ServiceHealth>,
      loadedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ServiceHealth>> getServicesHealth() async {
    final services = ['iam', 'pim', 'webdata'];
    final healths = await Future.wait(
      services.map(_pingService),
    );
    return healths;
  }

  // ─── Sección IAM ──────────────────────────────────────────────────────────

  Future<IamStats?> _fetchIamStats() async {
    // Cada contador aísla su propio error: si falla /roles, igual mostramos
    // tenants y planes. Solo se devuelve null si TODOS fallan.
    final results = await Future.wait([
      _safeCount('$_iam/tenants'),
      _safeCount('$_iam/roles'),
      _safeCount('$_iam/plans'),
    ]);

    if (results.every((r) => r == null)) return null;

    return IamStats(
      activeTenants: results[0] ?? 0,
      newTenantsLast24h: 0,
      totalRoles: results[1] ?? 0,
      totalPlans: results[2] ?? 0,
    );
  }

  // ─── Sección PIM ─────────────────────────────────────────────────────────

  /// Métricas de PIM vía el endpoint agregado de overview del marketplace.
  ///
  /// Un solo request a `/pim/api/v1/marketplace/overview` (excluido de la
  /// validación de tenant, autoriza por `X-User-Role: marketplace_admin` que
  /// el interceptor ya envía) devuelve categorías, marcas, productos del
  /// catálogo global y atributos a nivel plataforma. Reemplaza las 4 llamadas
  /// previas a endpoints tenant-scoped (`/categories`, `/brands`, ...) que
  /// devolvían 401 para un admin sin tenant y tumbaban toda la sección.
  Future<PimStats?> _fetchPimStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_pim/marketplace/overview',
        queryParameters: {
          'sections': 'dashboard,brands',
          'include_stats': 'true',
        },
        // El overview exige X-Tenant-ID; "global" = vista de plataforma.
        headers: const {'X-Tenant-ID': 'global'},
      );

      final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
      final dashboard =
          (data['dashboard'] as Map<String, dynamic>?) ?? const {};
      final brands = (data['brands'] as Map<String, dynamic>?) ?? const {};

      return PimStats(
        totalCategories: _extractInt(dashboard, 'total_categories') ?? 0,
        verifiedBrands: _extractInt(brands, 'verified_brands') ?? 0,
        totalBrands: _extractInt(brands, 'total_brands') ??
            _extractInt(dashboard, 'total_brands') ??
            0,
        // El overview no expone productos verificados por separado.
        verifiedProducts: 0,
        totalProducts: _extractInt(dashboard, 'total_global_products') ?? 0,
        totalAttributes: _extractInt(dashboard, 'total_attributes') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Sección Web Data ─────────────────────────────────────────────────────

  /// Métricas de Web Data vía `/webdata/api/v1/stats`.
  ///
  /// El endpoint correcto es `/stats` (no `/dashboard`, que no existe). Para
  /// la vista de plataforma se autentica por `X-API-Key` de marketplace admin
  /// → el backend usa el tenant "global". Con JWT solo, webdata exigiría un
  /// `X-Tenant-ID` UUID válido (400 con "global"), por eso va con API-Key.
  /// La respuesta viene envuelta en `{ "data": { ... } }`.
  Future<WebDataStats?> _fetchWebDataStats() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_webdata/stats',
        headers: const {'X-API-Key': _marketplaceAdminApiKey},
      );
      final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
      return WebDataStats(
        activeSources: _extractInt(data, 'active_sources') ?? 0,
        runningJobs: _extractInt(data, 'running_jobs') ?? 0,
        // No hay métrica "scrapeados hoy"; usamos el total de productos.
        productsScrapedToday: _extractInt(data, 'total_products') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Sección Quickstart ───────────────────────────────────────────────────

  Future<QuickstartStats?> _fetchQuickstartStats() async {
    try {
      final results = await Future.wait([
        _fetchActiveCount('$_pim/business-types'),
        _fetchActiveCount('$_pim/quickstart/templates'),
      ]);

      return QuickstartStats(
        activeBusinessTypes: results[0],
        activeTemplates: results[1],
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Health ───────────────────────────────────────────────────────────────

  Future<ServiceHealth> _pingService(String service) async {
    final path = _healthPath(service);
    final stopwatch = Stopwatch()..start();
    try {
      await _client.get<dynamic>(path);
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      final status =
          ms > _degradedLatencyMs ? ServiceStatus.degraded : ServiceStatus.online;
      return ServiceHealth(service: service, status: status, latencyMs: ms);
    } catch (_) {
      stopwatch.stop();
      return ServiceHealth(service: service, status: ServiceStatus.offline);
    }
  }

  String _healthPath(String service) {
    switch (service) {
      case 'iam':
        return '$_iam/health';
      case 'pim':
        return '$_pim/health';
      case 'webdata':
        return '$_webdata/health';
      default:
        return '/$service/api/v1/health';
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<int> _fetchCount(String path) async {
    final response =
        await _client.get<Map<String, dynamic>>('$path?page_size=1');
    return _extractTotal(response.data ?? {});
  }

  /// Variante tolerante a fallos de [_fetchCount]: devuelve null en vez de
  /// propagar la excepción, para aislar el error de un contador puntual.
  Future<int?> _safeCount(String path) async {
    try {
      return await _fetchCount(path);
    } catch (_) {
      return null;
    }
  }

  Future<int> _fetchActiveCount(String path) async {
    final response = await _client
        .get<Map<String, dynamic>>('$path?status=active&page_size=1');
    return _extractTotal(response.data ?? {});
  }

  int _extractTotal(Map<String, dynamic> data) {
    return _extractInt(data, 'total') ??
        _extractInt(data, 'total_count') ??
        _extractInt(data, 'count') ??
        0;
  }

  int? _extractInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
