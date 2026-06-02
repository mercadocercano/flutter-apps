import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('WebJobStatus enum', () {
    test('tiene exactamente 4 valores', () {
      expect(WebJobStatus.values, hasLength(4));
    });

    test('contiene running, completed, failed, cancelled', () {
      expect(
        WebJobStatus.values,
        containsAll([
          WebJobStatus.running,
          WebJobStatus.completed,
          WebJobStatus.failed,
          WebJobStatus.cancelled,
        ]),
      );
    });

    test('los valores son distintos entre sí', () {
      final values = WebJobStatus.values;
      final unique = values.toSet();
      expect(unique.length, values.length);
    });
  });
}
