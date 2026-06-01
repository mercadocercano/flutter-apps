import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

TemplateAnalytics buildAnalytics({
  String templateId = 'tmpl-1',
  int tenantsCount = 0,
  DateTime? lastActivatedAt,
  double completionRate = 0.0,
}) {
  return TemplateAnalytics(
    templateId: templateId,
    tenantsCount: tenantsCount,
    lastActivatedAt: lastActivatedAt,
    completionRate: completionRate,
  );
}

void main() {
  group('TemplateAnalytics value object', () {
    test('construye correctamente con campos obligatorios', () {
      final analytics = buildAnalytics();
      expect(analytics.templateId, 'tmpl-1');
      expect(analytics.tenantsCount, 0);
      expect(analytics.lastActivatedAt, isNull);
      expect(analytics.completionRate, 0.0);
    });

    test('construye con lastActivatedAt', () {
      final activatedAt = DateTime(2025, 6, 10);
      final analytics = buildAnalytics(
        tenantsCount: 5,
        lastActivatedAt: activatedAt,
        completionRate: 0.75,
      );
      expect(analytics.tenantsCount, 5);
      expect(analytics.lastActivatedAt, activatedAt);
      expect(analytics.completionRate, 0.75);
    });

    test('igualdad por valor (Equatable)', () {
      final a1 = buildAnalytics(tenantsCount: 3, completionRate: 0.6);
      final a2 = buildAnalytics(tenantsCount: 3, completionRate: 0.6);
      expect(a1, equals(a2));
    });

    test('distinto templateId genera objetos distintos', () {
      final a1 = buildAnalytics(templateId: 'tmpl-1');
      final a2 = buildAnalytics(templateId: 'tmpl-2');
      expect(a1, isNot(equals(a2)));
    });

    test('distinto tenantsCount genera objetos distintos', () {
      final a1 = buildAnalytics(tenantsCount: 0);
      final a2 = buildAnalytics(tenantsCount: 10);
      expect(a1, isNot(equals(a2)));
    });

    test('distinto completionRate genera objetos distintos', () {
      final a1 = buildAnalytics(completionRate: 0.3);
      final a2 = buildAnalytics(completionRate: 0.9);
      expect(a1, isNot(equals(a2)));
    });

    test('distinto lastActivatedAt genera objetos distintos', () {
      final a1 = buildAnalytics(lastActivatedAt: DateTime(2025, 1, 1));
      final a2 = buildAnalytics(lastActivatedAt: DateTime(2025, 6, 1));
      expect(a1, isNot(equals(a2)));
    });

    group('hasBeenUsed', () {
      test('false cuando tenantsCount es 0', () {
        final analytics = buildAnalytics(tenantsCount: 0);
        expect(analytics.hasBeenUsed, isFalse);
      });

      test('true cuando tenantsCount es 1', () {
        final analytics = buildAnalytics(tenantsCount: 1);
        expect(analytics.hasBeenUsed, isTrue);
      });

      test('true cuando tenantsCount es mayor que 1', () {
        final analytics = buildAnalytics(tenantsCount: 100);
        expect(analytics.hasBeenUsed, isTrue);
      });
    });

    group('isCompletionAcceptable', () {
      test('false cuando completionRate es 0.0', () {
        final analytics = buildAnalytics(completionRate: 0.0);
        expect(analytics.isCompletionAcceptable, isFalse);
      });

      test('false cuando completionRate es 0.49', () {
        final analytics = buildAnalytics(completionRate: 0.49);
        expect(analytics.isCompletionAcceptable, isFalse);
      });

      test('true cuando completionRate es exactamente 0.5', () {
        final analytics = buildAnalytics(completionRate: 0.5);
        expect(analytics.isCompletionAcceptable, isTrue);
      });

      test('true cuando completionRate es 0.75', () {
        final analytics = buildAnalytics(completionRate: 0.75);
        expect(analytics.isCompletionAcceptable, isTrue);
      });

      test('true cuando completionRate es 1.0', () {
        final analytics = buildAnalytics(completionRate: 1.0);
        expect(analytics.isCompletionAcceptable, isTrue);
      });
    });

    test('props incluye todos los campos', () {
      final activatedAt = DateTime(2025, 3, 20);
      final analytics = buildAnalytics(
        templateId: 'tmpl-42',
        tenantsCount: 7,
        lastActivatedAt: activatedAt,
        completionRate: 0.8,
      );
      expect(
        analytics.props,
        containsAll([
          analytics.templateId,
          analytics.tenantsCount,
          analytics.lastActivatedAt,
          analytics.completionRate,
        ]),
      );
    });

    test('con lastActivatedAt null — props lo incluye como null', () {
      final analytics = buildAnalytics(lastActivatedAt: null);
      expect(analytics.props, contains(null));
    });
  });
}
