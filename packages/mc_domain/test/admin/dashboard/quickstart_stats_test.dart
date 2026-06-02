import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

QuickstartStats buildQuickstartStats({
  int activeBusinessTypes = 12,
  int activeTemplates = 35,
}) {
  return QuickstartStats(
    activeBusinessTypes: activeBusinessTypes,
    activeTemplates: activeTemplates,
  );
}

void main() {
  group('QuickstartStats value object', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildQuickstartStats();
      expect(stats.activeBusinessTypes, 12);
      expect(stats.activeTemplates, 35);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildQuickstartStats();
      final s2 = buildQuickstartStats();
      expect(s1, equals(s2));
    });

    test('distintos activeBusinessTypes generan objetos distintos', () {
      final s1 = buildQuickstartStats(activeBusinessTypes: 5);
      final s2 = buildQuickstartStats(activeBusinessTypes: 15);
      expect(s1, isNot(equals(s2)));
    });

    test('distintos activeTemplates generan objetos distintos', () {
      final s1 = buildQuickstartStats(activeTemplates: 10);
      final s2 = buildQuickstartStats(activeTemplates: 50);
      expect(s1, isNot(equals(s2)));
    });

    test('props incluye ambos campos', () {
      final stats = buildQuickstartStats();
      expect(stats.props, equals([12, 35]));
    });

    test('acepta valores cero', () {
      final stats = buildQuickstartStats(
        activeBusinessTypes: 0,
        activeTemplates: 0,
      );
      expect(stats.activeBusinessTypes, 0);
      expect(stats.activeTemplates, 0);
    });
  });
}
