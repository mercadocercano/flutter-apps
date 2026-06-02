import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

WebDataStats buildWebDataStats({
  int activeSources = 8,
  int runningJobs = 3,
  int productsScrapedToday = 1200,
}) {
  return WebDataStats(
    activeSources: activeSources,
    runningJobs: runningJobs,
    productsScrapedToday: productsScrapedToday,
  );
}

void main() {
  group('WebDataStats value object', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildWebDataStats();
      expect(stats.activeSources, 8);
      expect(stats.runningJobs, 3);
      expect(stats.productsScrapedToday, 1200);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildWebDataStats();
      final s2 = buildWebDataStats();
      expect(s1, equals(s2));
    });

    test('distintos activeSources generan objetos distintos', () {
      final s1 = buildWebDataStats(activeSources: 5);
      final s2 = buildWebDataStats(activeSources: 10);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos runningJobs generan objetos distintos', () {
      final s1 = buildWebDataStats(runningJobs: 1);
      final s2 = buildWebDataStats(runningJobs: 5);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos productsScrapedToday generan objetos distintos', () {
      final s1 = buildWebDataStats(productsScrapedToday: 100);
      final s2 = buildWebDataStats(productsScrapedToday: 999);
      expect(s1, isNot(equals(s2)));
    });

    test('props incluye todos los campos', () {
      final stats = buildWebDataStats();
      expect(stats.props, containsAll([8, 3, 1200]));
    });

    test('acepta valores cero en todos los campos', () {
      final stats = buildWebDataStats(
        activeSources: 0,
        runningJobs: 0,
        productsScrapedToday: 0,
      );
      expect(stats.activeSources, 0);
      expect(stats.runningJobs, 0);
      expect(stats.productsScrapedToday, 0);
    });
  });
}
