import 'dart:async';

import 'package:mc_domain/mc_domain.dart';

import '../../http/admin_http_client.dart';

/// Implementación HTTP de [DashboardRepository].
///
/// Compone estadísticas de múltiples endpoints vía Kong en paralelo.
/// Cada sección aísla sus errores: si un endpoint falla, retorna null
/// para esa sección sin bloquear el resto del dashboard.
///
/// Rutas:
/// - IAM: /iam/api/v1/tenants, /iam/api/v1/roles, /iam/api/v1/plans
/// - PIM: /pim/api/v1/categories, /pim/api/v1/brands, /pim/api/v1/global-catalog/products, /pim/api/v1/attributes
/// - WebData: /webdata/api/v1/dashboard
/// - Quickstart: /pim/api/v1/business-types, /pim/api/v1/quickstart/templates
/// - Health: pings a cada servicio midiendo latencia con Stopwatch
class DashboardRepositoryImpl implements DashboardRepository {
  static const _iam = '/iam/api/v1';
  static const _pim = '/pim/api/v1';
  static const _webdata = '/webdata/api/v1';

  static const _degradedLatencyMs = 1000;

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
    try {
      final results = await Future.wait([
        _fetchCount('$_iam/tenants'),
        _fetchCount('$_iam/roles'),
        _fetchCount('$_iam/plans'),
      ]);

      return IamStats(
        activeTenants: results[0],
        newTenantsLast24h: 0,
        totalRoles: results[1],
        totalPlans: results[2],
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Sección PIM ─────────────────────────────────────────────────────────

  Future<PimStats?> _fetchPimStats() async {
    try {
      final results = await Future.wait([
        _fetchCount('$_pim/categories'),
        _fetchPimBrandsStats(),
        _fetchPimProductsStats(),
        _fetchCount('$_pim/attributes'),
      ]);

      final brands = results[1] as _BrandCounts;
      final products = results[2] as _ProductCounts;

      return PimStats(
        totalCategories: results[0] as int,
        verifiedBrands: brands.verified,
        totalBrands: brands.total,
        verifiedProducts: products.verified,
        totalProducts: products.total,
        totalAttributes: results[3] as int,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_BrandCounts> _fetchPimBrandsStats() async {
    final response =
        await _client.get<Map<String, dynamic>>('$_pim/brands?page_size=1');
    final data = response.data ?? {};
    final total = _extractTotal(data);
    final verified = _extractInt(data, 'verified_count') ?? 0;
    return _BrandCounts(total: total, verified: verified);
  }

  Future<_ProductCounts> _fetchPimProductsStats() async {
    final response = await _client
        .get<Map<String, dynamic>>('$_pim/global-catalog/products?page_size=1');
    final data = response.data ?? {};
    final total = _extractTotal(data);
    final verified = _extractInt(data, 'verified_count') ?? 0;
    return _ProductCounts(total: total, verified: verified);
  }

  // ─── Sección Web Data ─────────────────────────────────────────────────────

  Future<WebDataStats?> _fetchWebDataStats() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('$_webdata/dashboard');
      final data = response.data ?? {};
      return WebDataStats(
        activeSources: _extractInt(data, 'active_sources') ?? 0,
        runningJobs: _extractInt(data, 'running_jobs') ?? 0,
        productsScrapedToday: _extractInt(data, 'products_scraped_today') ?? 0,
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

// ---------------------------------------------------------------------------
// DTOs internos
// ---------------------------------------------------------------------------

class _BrandCounts {
  final int total;
  final int verified;
  const _BrandCounts({required this.total, required this.verified});
}

class _ProductCounts {
  final int total;
  final int verified;
  const _ProductCounts({required this.total, required this.verified});
}
