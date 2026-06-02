import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

WebDataDashboardStats buildStats({
  int activeSources = 5,
  int inactiveSources = 2,
  int jobsToday = 10,
  int totalProducts = 1000,
  double successRate = 0.8,
}) {
  return WebDataDashboardStats(
    activeSources: activeSources,
    inactiveSources: inactiveSources,
    jobsToday: jobsToday,
    totalProducts: totalProducts,
    successRate: successRate,
  );
}

void main() {
  group('WebDataDashboardStats value object', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildStats();
      expect(stats.activeSources, 5);
      expect(stats.inactiveSources, 2);
      expect(stats.jobsToday, 10);
      expect(stats.totalProducts, 1000);
      expect(stats.successRate, 0.8);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildStats();
      final s2 = buildStats();
      expect(s1, equals(s2));
    });

    test('distintos activeSources generan objetos distintos', () {
      final s1 = buildStats(activeSources: 5);
      final s2 = buildStats(activeSources: 10);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos successRate generan objetos distintos', () {
      final s1 = buildStats(successRate: 0.5);
      final s2 = buildStats(successRate: 1.0);
      expect(s1, isNot(equals(s2)));
    });

    group('totalSources', () {
      test('suma activeSources + inactiveSources', () {
        final stats = buildStats(activeSources: 7, inactiveSources: 3);
        expect(stats.totalSources, 10);
      });

      test('cero cuando ambos son cero', () {
        final stats = buildStats(activeSources: 0, inactiveSources: 0);
        expect(stats.totalSources, 0);
      });
    });

    group('successRatePercent', () {
      test('0 cuando successRate es 0.0', () {
        final stats = buildStats(successRate: 0.0);
        expect(stats.successRatePercent, 0);
      });

      test('100 cuando successRate es 1.0', () {
        final stats = buildStats(successRate: 1.0);
        expect(stats.successRatePercent, 100);
      });

      test('80 cuando successRate es 0.8', () {
        final stats = buildStats(successRate: 0.8);
        expect(stats.successRatePercent, 80);
      });

      test('redondea correctamente — 0.755 → 76', () {
        final stats = buildStats(successRate: 0.755);
        expect(stats.successRatePercent, 76);
      });

      test('redondea correctamente — 0.745 → 75', () {
        final stats = buildStats(successRate: 0.745);
        expect(stats.successRatePercent, 75);
      });
    });

    test('props incluye todos los campos', () {
      final stats = buildStats();
      expect(
        stats.props,
        containsAll([
          stats.activeSources,
          stats.inactiveSources,
          stats.jobsToday,
          stats.totalProducts,
          stats.successRate,
        ]),
      );
    });

    test('distintos totalProducts generan objetos distintos', () {
      final s1 = buildStats(totalProducts: 100);
      final s2 = buildStats(totalProducts: 200);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos jobsToday generan objetos distintos', () {
      final s1 = buildStats(jobsToday: 5);
      final s2 = buildStats(jobsToday: 15);
      expect(s1, isNot(equals(s2)));
    });
  });
}
