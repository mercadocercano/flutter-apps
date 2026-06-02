import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDashboardRepository extends Mock implements DashboardRepository {}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 5, 31, 10);

IamStats _buildIamStats() => const IamStats(
      activeTenants: 42,
      newTenantsLast24h: 3,
      totalRoles: 8,
      totalPlans: 4,
    );

PimStats _buildPimStats() => const PimStats(
      totalCategories: 120,
      verifiedBrands: 80,
      totalBrands: 100,
      verifiedProducts: 3000,
      totalProducts: 4000,
      totalAttributes: 55,
    );

WebDataStats _buildWebDataStats() => const WebDataStats(
      activeSources: 5,
      runningJobs: 2,
      productsScrapedToday: 850,
    );

QuickstartStats _buildQuickstartStats() => const QuickstartStats(
      activeBusinessTypes: 12,
      activeTemplates: 34,
    );

ServiceHealth _buildHealth(String service, ServiceStatus status) =>
    ServiceHealth(service: service, status: status, latencyMs: 50);

DashboardStats _buildFullStats() => DashboardStats(
      iam: _buildIamStats(),
      pim: _buildPimStats(),
      webData: _buildWebDataStats(),
      quickstart: _buildQuickstartStats(),
      services: [
        _buildHealth('iam', ServiceStatus.online),
        _buildHealth('pim', ServiceStatus.online),
      ],
      loadedAt: _now,
    );

DashboardStats _buildPartialStats() => DashboardStats(
      iam: _buildIamStats(),
      pim: null,
      webData: _buildWebDataStats(),
      quickstart: null,
      services: [
        _buildHealth('iam', ServiceStatus.online),
        _buildHealth('pim', ServiceStatus.offline),
      ],
      loadedAt: _now,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDashboardRepository repository;

  setUp(() {
    repository = MockDashboardRepository();
  });

  // ─── GetAdminDashboardStatsUseCase ────────────────────────────────────────

  group('GetAdminDashboardStatsUseCase', () {
    test('delega en repository.getDashboardStats y retorna stats completas',
        () async {
      // Arrange
      final stats = _buildFullStats();
      when(() => repository.getDashboardStats())
          .thenAnswer((_) async => stats);
      final useCase = GetAdminDashboardStatsUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.iam?.activeTenants, 42);
      expect(result.pim?.totalCategories, 120);
      expect(result.hasPartialData, isFalse);
      verify(() => repository.getDashboardStats()).called(1);
    });

    test('retorna stats parciales cuando un servicio falla', () async {
      // Arrange
      final stats = _buildPartialStats();
      when(() => repository.getDashboardStats())
          .thenAnswer((_) async => stats);
      final useCase = GetAdminDashboardStatsUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.iam, isNotNull);
      expect(result.pim, isNull);
      expect(result.hasPartialData, isTrue);
      expect(result.allServicesOnline, isFalse);
    });

    test('propaga excepcion si el repositorio lanza error critico', () async {
      // Arrange
      when(() => repository.getDashboardStats())
          .thenThrow(Exception('Connection refused'));
      final useCase = GetAdminDashboardStatsUseCase(repository);

      // Act & Assert
      expect(() => useCase.execute(), throwsException);
    });

    test('llama al repositorio exactamente una vez por ejecucion', () async {
      // Arrange
      when(() => repository.getDashboardStats())
          .thenAnswer((_) async => _buildFullStats());
      final useCase = GetAdminDashboardStatsUseCase(repository);

      // Act
      await useCase.execute();
      await useCase.execute();

      // Assert
      verify(() => repository.getDashboardStats()).called(2);
    });
  });

  // ─── GetServicesHealthUseCase ─────────────────────────────────────────────

  group('GetServicesHealthUseCase', () {
    test('retorna lista de salud de servicios', () async {
      // Arrange
      final services = [
        _buildHealth('iam', ServiceStatus.online),
        _buildHealth('pim', ServiceStatus.degraded),
        _buildHealth('webdata', ServiceStatus.offline),
      ];
      when(() => repository.getServicesHealth())
          .thenAnswer((_) async => services);
      final useCase = GetServicesHealthUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.length, 3);
      expect(result[0].isOnline, isTrue);
      expect(result[1].status, ServiceStatus.degraded);
      expect(result[2].isOnline, isFalse);
      verify(() => repository.getServicesHealth()).called(1);
    });

    test('retorna lista vacia si no hay servicios monitoreados', () async {
      // Arrange
      when(() => repository.getServicesHealth())
          .thenAnswer((_) async => []);
      final useCase = GetServicesHealthUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isEmpty);
    });

    test('servicio offline tiene hasIssue=true', () async {
      // Arrange
      final services = [_buildHealth('pim', ServiceStatus.offline)];
      when(() => repository.getServicesHealth())
          .thenAnswer((_) async => services);
      final useCase = GetServicesHealthUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.first.hasIssue, isTrue);
    });
  });

  // ─── RefreshDashboardUseCase ─────────────────────────────────────────────

  group('RefreshDashboardUseCase', () {
    test('delega en repository.getDashboardStats igual que GetAdminDashboardStatsUseCase',
        () async {
      // Arrange
      final stats = _buildFullStats();
      when(() => repository.getDashboardStats())
          .thenAnswer((_) async => stats);
      final useCase = RefreshDashboardUseCase(repository);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.loadedAt, _now);
      verify(() => repository.getDashboardStats()).called(1);
    });

    test('propagates exception on network failure', () async {
      // Arrange
      when(() => repository.getDashboardStats())
          .thenThrow(Exception('timeout'));
      final useCase = RefreshDashboardUseCase(repository);

      // Act & Assert
      expect(() => useCase.execute(), throwsException);
    });

    test('retorna datos actualizados en cada llamada', () async {
      // Arrange
      var callCount = 0;
      when(() => repository.getDashboardStats()).thenAnswer((_) async {
        callCount++;
        return DashboardStats(
          iam: IamStats(
            activeTenants: callCount * 10,
            newTenantsLast24h: 0,
            totalRoles: 0,
            totalPlans: 0,
          ),
          services: [],
          loadedAt: _now,
        );
      });
      final useCase = RefreshDashboardUseCase(repository);

      // Act
      final first = await useCase.execute();
      final second = await useCase.execute();

      // Assert
      expect(first.iam?.activeTenants, 10);
      expect(second.iam?.activeTenants, 20);
    });
  });
}
