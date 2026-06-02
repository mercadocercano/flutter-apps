import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

// --- Builders ---

IamStats buildIam() => const IamStats(
      activeTenants: 10,
      newTenantsLast24h: 2,
      totalRoles: 5,
      totalPlans: 3,
    );

PimStats buildPim() => const PimStats(
      totalCategories: 50,
      verifiedBrands: 80,
      totalBrands: 100,
      verifiedProducts: 400,
      totalProducts: 500,
      totalAttributes: 30,
    );

WebDataStats buildWebData() => const WebDataStats(
      activeSources: 8,
      runningJobs: 3,
      productsScrapedToday: 1200,
    );

QuickstartStats buildQuickstart() => const QuickstartStats(
      activeBusinessTypes: 12,
      activeTemplates: 35,
    );

ServiceHealth buildOnlineService(String name) => ServiceHealth(
      service: name,
      status: ServiceStatus.online,
      latencyMs: 50,
    );

ServiceHealth buildOfflineService(String name) => ServiceHealth(
      service: name,
      status: ServiceStatus.offline,
      latencyMs: null,
    );

// Sentinel para distinguir "no se pasó valor" de "se pasó null explícitamente".
final _defaultIam = buildIam();
final _defaultPim = buildPim();
final _defaultWebData = buildWebData();
final _defaultQuickstart = buildQuickstart();

DashboardStats buildFullDashboard({
  Object? iam = const _Default(),
  Object? pim = const _Default(),
  Object? webData = const _Default(),
  Object? quickstart = const _Default(),
  List<ServiceHealth>? services,
  DateTime? loadedAt,
}) {
  return DashboardStats(
    iam: iam is _Default ? _defaultIam : iam as IamStats?,
    pim: pim is _Default ? _defaultPim : pim as PimStats?,
    webData: webData is _Default ? _defaultWebData : webData as WebDataStats?,
    quickstart: quickstart is _Default
        ? _defaultQuickstart
        : quickstart as QuickstartStats?,
    services: services ??
        [
          buildOnlineService('kong'),
          buildOnlineService('iam'),
          buildOnlineService('pim'),
        ],
    loadedAt: loadedAt ?? DateTime(2026, 1, 15, 10, 0),
  );
}

class _Default {
  const _Default();
}

// --- Tests ---

void main() {
  group('DashboardStats aggregate', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildFullDashboard();
      expect(stats.iam, isNotNull);
      expect(stats.pim, isNotNull);
      expect(stats.webData, isNotNull);
      expect(stats.quickstart, isNotNull);
      expect(stats.services.length, 3);
    });

    test('acepta secciones nulas (datos parciales)', () {
      final stats = DashboardStats(
        iam: null,
        pim: null,
        webData: null,
        quickstart: null,
        services: const [],
        loadedAt: DateTime(2026, 1, 15),
      );
      expect(stats.iam, isNull);
      expect(stats.pim, isNull);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildFullDashboard();
      final s2 = buildFullDashboard();
      expect(s1, equals(s2));
    });

    test('distintos loadedAt generan objetos distintos', () {
      final s1 = buildFullDashboard(loadedAt: DateTime(2026, 1, 1));
      final s2 = buildFullDashboard(loadedAt: DateTime(2026, 1, 2));
      expect(s1, isNot(equals(s2)));
    });

    group('allServicesOnline', () {
      test('true cuando todos los servicios están online', () {
        final stats = buildFullDashboard(
          services: [
            buildOnlineService('kong'),
            buildOnlineService('iam'),
            buildOnlineService('pim'),
          ],
        );
        expect(stats.allServicesOnline, isTrue);
      });

      test('false cuando un servicio está offline', () {
        final stats = buildFullDashboard(
          services: [
            buildOnlineService('kong'),
            buildOfflineService('pim'),
          ],
        );
        expect(stats.allServicesOnline, isFalse);
      });

      test('false cuando un servicio está degraded', () {
        final stats = buildFullDashboard(
          services: [
            buildOnlineService('kong'),
            ServiceHealth(
              service: 'iam',
              status: ServiceStatus.degraded,
              latencyMs: 800,
            ),
          ],
        );
        expect(stats.allServicesOnline, isFalse);
      });

      test('true cuando la lista de servicios está vacía', () {
        // every() sobre lista vacía retorna true — comportamiento esperado de Dart
        final stats = buildFullDashboard(services: []);
        expect(stats.allServicesOnline, isTrue);
      });
    });

    group('hasPartialData', () {
      test('false cuando todas las secciones tienen datos', () {
        final stats = buildFullDashboard();
        expect(stats.hasPartialData, isFalse);
      });

      test('true cuando iam es null', () {
        final stats = buildFullDashboard(iam: null);
        expect(stats.hasPartialData, isTrue);
      });

      test('true cuando pim es null', () {
        final stats = buildFullDashboard(pim: null);
        expect(stats.hasPartialData, isTrue);
      });

      test('true cuando webData es null', () {
        final stats = buildFullDashboard(webData: null);
        expect(stats.hasPartialData, isTrue);
      });

      test('true cuando quickstart es null', () {
        final stats = buildFullDashboard(quickstart: null);
        expect(stats.hasPartialData, isTrue);
      });

      test('true cuando todas las secciones son null', () {
        final stats = DashboardStats(
          iam: null,
          pim: null,
          webData: null,
          quickstart: null,
          services: const [],
          loadedAt: DateTime(2026, 1, 15),
        );
        expect(stats.hasPartialData, isTrue);
      });
    });

    test('props incluye todos los campos', () {
      final loadedAt = DateTime(2026, 1, 15, 10, 0);
      final services = [buildOnlineService('kong')];
      final stats = DashboardStats(
        iam: buildIam(),
        pim: buildPim(),
        webData: buildWebData(),
        quickstart: buildQuickstart(),
        services: services,
        loadedAt: loadedAt,
      );
      expect(stats.props.length, 6);
      expect(stats.props[4], same(services));
      expect(stats.props[5], loadedAt);
    });
  });
}
