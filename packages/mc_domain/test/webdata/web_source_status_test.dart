import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('WebSourceStatus enum', () {
    test('tiene exactamente 4 valores', () {
      expect(WebSourceStatus.values, hasLength(4));
    });

    test('contiene active, inactive, running, error', () {
      expect(
        WebSourceStatus.values,
        containsAll([
          WebSourceStatus.active,
          WebSourceStatus.inactive,
          WebSourceStatus.running,
          WebSourceStatus.error,
        ]),
      );
    });

    test('los valores son distintos entre sí', () {
      final values = WebSourceStatus.values;
      final unique = values.toSet();
      expect(unique.length, values.length);
    });
  });
}
