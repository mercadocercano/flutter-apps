import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

IamStats buildIamStats({
  int activeTenants = 10,
  int newTenantsLast24h = 2,
  int totalRoles = 5,
  int totalPlans = 3,
}) {
  return IamStats(
    activeTenants: activeTenants,
    newTenantsLast24h: newTenantsLast24h,
    totalRoles: totalRoles,
    totalPlans: totalPlans,
  );
}

void main() {
  group('IamStats value object', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildIamStats();
      expect(stats.activeTenants, 10);
      expect(stats.newTenantsLast24h, 2);
      expect(stats.totalRoles, 5);
      expect(stats.totalPlans, 3);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildIamStats();
      final s2 = buildIamStats();
      expect(s1, equals(s2));
    });

    test('distintos activeTenants generan objetos distintos', () {
      final s1 = buildIamStats(activeTenants: 10);
      final s2 = buildIamStats(activeTenants: 20);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos newTenantsLast24h generan objetos distintos', () {
      final s1 = buildIamStats(newTenantsLast24h: 1);
      final s2 = buildIamStats(newTenantsLast24h: 5);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos totalRoles generan objetos distintos', () {
      final s1 = buildIamStats(totalRoles: 3);
      final s2 = buildIamStats(totalRoles: 8);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos totalPlans generan objetos distintos', () {
      final s1 = buildIamStats(totalPlans: 1);
      final s2 = buildIamStats(totalPlans: 4);
      expect(s1, isNot(equals(s2)));
    });

    test('props incluye todos los campos', () {
      final stats = buildIamStats();
      expect(stats.props, containsAll([10, 2, 5, 3]));
    });

    test('acepta valores cero en todos los campos', () {
      final stats = buildIamStats(
        activeTenants: 0,
        newTenantsLast24h: 0,
        totalRoles: 0,
        totalPlans: 0,
      );
      expect(stats.activeTenants, 0);
      expect(stats.newTenantsLast24h, 0);
    });
  });
}
