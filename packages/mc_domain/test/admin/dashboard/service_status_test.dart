import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceStatus enum', () {
    test('tiene exactamente tres valores', () {
      expect(ServiceStatus.values.length, 3);
    });

    test('contiene online', () {
      expect(ServiceStatus.values, contains(ServiceStatus.online));
    });

    test('contiene degraded', () {
      expect(ServiceStatus.values, contains(ServiceStatus.degraded));
    });

    test('contiene offline', () {
      expect(ServiceStatus.values, contains(ServiceStatus.offline));
    });

    test('online != degraded', () {
      expect(ServiceStatus.online, isNot(ServiceStatus.degraded));
    });

    test('online != offline', () {
      expect(ServiceStatus.online, isNot(ServiceStatus.offline));
    });

    test('degraded != offline', () {
      expect(ServiceStatus.degraded, isNot(ServiceStatus.offline));
    });
  });
}
