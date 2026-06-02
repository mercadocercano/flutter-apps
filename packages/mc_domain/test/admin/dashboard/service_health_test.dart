import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

ServiceHealth buildHealth({
  String service = 'kong',
  ServiceStatus status = ServiceStatus.online,
  int? latencyMs = 42,
}) {
  return ServiceHealth(service: service, status: status, latencyMs: latencyMs);
}

void main() {
  group('ServiceHealth value object', () {
    test('construye correctamente con todos los campos', () {
      final h = buildHealth();
      expect(h.service, 'kong');
      expect(h.status, ServiceStatus.online);
      expect(h.latencyMs, 42);
    });

    test('latencyMs puede ser null cuando está offline', () {
      final h = buildHealth(status: ServiceStatus.offline, latencyMs: null);
      expect(h.latencyMs, isNull);
    });

    test('igualdad por valor (Equatable)', () {
      final h1 = buildHealth();
      final h2 = buildHealth();
      expect(h1, equals(h2));
    });

    test('distintos service generan objetos distintos', () {
      final h1 = buildHealth(service: 'kong');
      final h2 = buildHealth(service: 'iam');
      expect(h1, isNot(equals(h2)));
    });

    test('distintos status generan objetos distintos', () {
      final h1 = buildHealth(status: ServiceStatus.online);
      final h2 = buildHealth(status: ServiceStatus.offline);
      expect(h1, isNot(equals(h2)));
    });

    test('distintos latencyMs generan objetos distintos', () {
      final h1 = buildHealth(latencyMs: 10);
      final h2 = buildHealth(latencyMs: 500);
      expect(h1, isNot(equals(h2)));
    });

    group('isOnline', () {
      test('true cuando status es online', () {
        final h = buildHealth(status: ServiceStatus.online);
        expect(h.isOnline, isTrue);
      });

      test('false cuando status es degraded', () {
        final h = buildHealth(status: ServiceStatus.degraded);
        expect(h.isOnline, isFalse);
      });

      test('false cuando status es offline', () {
        final h = buildHealth(status: ServiceStatus.offline);
        expect(h.isOnline, isFalse);
      });
    });

    group('hasIssue', () {
      test('false cuando status es online', () {
        final h = buildHealth(status: ServiceStatus.online);
        expect(h.hasIssue, isFalse);
      });

      test('true cuando status es degraded', () {
        final h = buildHealth(status: ServiceStatus.degraded);
        expect(h.hasIssue, isTrue);
      });

      test('true cuando status es offline', () {
        final h = buildHealth(status: ServiceStatus.offline);
        expect(h.hasIssue, isTrue);
      });
    });

    test('props incluye service, status y latencyMs', () {
      final h = buildHealth(service: 'pim', status: ServiceStatus.degraded, latencyMs: 300);
      expect(h.props, equals(['pim', ServiceStatus.degraded, 300]));
    });
  });
}
