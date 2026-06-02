import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

WebSource buildWebSource({
  String id = 'src-1',
  String name = 'MercadoLibre Ferretería',
  String url = 'https://example.com/ferreteria',
  WebSourceStatus status = WebSourceStatus.active,
  String? schedule,
  List<String> businessTypeIds = const ['bt-1'],
}) {
  final now = DateTime(2026, 1, 15);
  return WebSource(
    id: id,
    name: name,
    url: url,
    status: status,
    schedule: schedule,
    businessTypeIds: businessTypeIds,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('WebSource entity', () {
    test('construye correctamente con campos obligatorios', () {
      final source = buildWebSource();
      expect(source.id, 'src-1');
      expect(source.name, 'MercadoLibre Ferretería');
      expect(source.url, 'https://example.com/ferreteria');
      expect(source.status, WebSourceStatus.active);
      expect(source.businessTypeIds, ['bt-1']);
      expect(source.schedule, isNull);
    });

    test('defaults correctos — businessTypeIds vacío y schedule null', () {
      final now = DateTime(2026, 1, 15);
      final source = WebSource(
        id: 'x',
        name: 'X',
        url: 'https://x.com',
        status: WebSourceStatus.inactive,
        createdAt: now,
        updatedAt: now,
      );
      expect(source.businessTypeIds, isEmpty);
      expect(source.schedule, isNull);
    });

    test('construye con schedule y múltiples businessTypeIds', () {
      final source = buildWebSource(
        schedule: '0 9 * * *',
        businessTypeIds: ['bt-1', 'bt-2', 'bt-3'],
      );
      expect(source.schedule, '0 9 * * *');
      expect(source.businessTypeIds, hasLength(3));
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildWebSource();
      final s2 = buildWebSource();
      expect(s1, equals(s2));
    });

    test('distintos ids generan entidades distintas', () {
      final s1 = buildWebSource(id: 'src-1');
      final s2 = buildWebSource(id: 'src-2');
      expect(s1, isNot(equals(s2)));
    });

    test('distinto status genera entidades distintas', () {
      final s1 = buildWebSource(status: WebSourceStatus.active);
      final s2 = buildWebSource(status: WebSourceStatus.inactive);
      expect(s1, isNot(equals(s2)));
    });

    group('canTrigger', () {
      test('true cuando status es active', () {
        final source = buildWebSource(status: WebSourceStatus.active);
        expect(source.canTrigger, isTrue);
      });

      test('true cuando status es inactive', () {
        final source = buildWebSource(status: WebSourceStatus.inactive);
        expect(source.canTrigger, isTrue);
      });

      test('true cuando status es error', () {
        final source = buildWebSource(status: WebSourceStatus.error);
        expect(source.canTrigger, isTrue);
      });

      test('false cuando status es running', () {
        final source = buildWebSource(status: WebSourceStatus.running);
        expect(source.canTrigger, isFalse);
      });
    });

    group('copyWith', () {
      test('cambia solo el name', () {
        final original = buildWebSource(name: 'Original');
        final updated = original.copyWith(name: 'Actualizado');
        expect(updated.name, 'Actualizado');
        expect(updated.id, original.id);
        expect(updated.url, original.url);
      });

      test('cambia el status', () {
        final original = buildWebSource(status: WebSourceStatus.active);
        final updated = original.copyWith(status: WebSourceStatus.running);
        expect(updated.status, WebSourceStatus.running);
        expect(updated.id, original.id);
      });

      test('cambia el schedule', () {
        final original = buildWebSource(schedule: null);
        final updated = original.copyWith(schedule: '0 8 * * 1-5');
        expect(updated.schedule, '0 8 * * 1-5');
        expect(updated.id, original.id);
      });

      test('cambia businessTypeIds', () {
        final original = buildWebSource(businessTypeIds: ['bt-1']);
        final updated = original.copyWith(businessTypeIds: ['bt-1', 'bt-2']);
        expect(updated.businessTypeIds, hasLength(2));
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildWebSource();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('puede sobreescribir createdAt y updatedAt', () {
        final original = buildWebSource();
        final newDate = DateTime(2026, 6, 1);
        final updated = original.copyWith(
          createdAt: newDate,
          updatedAt: newDate,
        );
        expect(updated.createdAt, newDate);
        expect(updated.updatedAt, newDate);
        expect(updated.id, original.id);
      });
    });

    test('props incluye todos los campos', () {
      final source = buildWebSource(schedule: '0 9 * * *');
      expect(
        source.props,
        containsAll([
          source.id,
          source.name,
          source.url,
          source.status,
          source.schedule,
          source.businessTypeIds,
          source.createdAt,
          source.updatedAt,
        ]),
      );
    });
  });
}
