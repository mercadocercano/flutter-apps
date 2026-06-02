import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AttributeType enum', () {
    test('tiene exactamente 5 valores', () {
      expect(AttributeType.values.length, 5);
    });

    test('todos los valores existen', () {
      expect(
        AttributeType.values,
        containsAll([
          AttributeType.text,
          AttributeType.number,
          AttributeType.boolean,
          AttributeType.select,
          AttributeType.multiSelect,
        ]),
      );
    });

    group('fromString', () {
      test('text', () {
        expect(AttributeType.fromString('text'), AttributeType.text);
      });

      test('number', () {
        expect(AttributeType.fromString('number'), AttributeType.number);
      });

      test('boolean', () {
        expect(AttributeType.fromString('boolean'), AttributeType.boolean);
      });

      test('select', () {
        expect(AttributeType.fromString('select'), AttributeType.select);
      });

      test('multi_select', () {
        expect(
          AttributeType.fromString('multi_select'),
          AttributeType.multiSelect,
        );
      });

      test('null → text por defecto', () {
        expect(AttributeType.fromString(null), AttributeType.text);
      });

      test('valor desconocido → text por defecto', () {
        expect(AttributeType.fromString('unknown'), AttributeType.text);
      });

      test('case insensitive — TEXT', () {
        expect(AttributeType.fromString('TEXT'), AttributeType.text);
      });

      test('case insensitive — SELECT', () {
        expect(AttributeType.fromString('SELECT'), AttributeType.select);
      });
    });

    group('toApiString', () {
      test('text → "text"', () {
        expect(AttributeType.text.toApiString(), 'text');
      });

      test('number → "number"', () {
        expect(AttributeType.number.toApiString(), 'number');
      });

      test('boolean → "boolean"', () {
        expect(AttributeType.boolean.toApiString(), 'boolean');
      });

      test('select → "select"', () {
        expect(AttributeType.select.toApiString(), 'select');
      });

      test('multiSelect → "multi_select"', () {
        expect(AttributeType.multiSelect.toApiString(), 'multi_select');
      });
    });

    group('hasValues', () {
      test('select tiene valores', () {
        expect(AttributeType.select.hasValues, isTrue);
      });

      test('multiSelect tiene valores', () {
        expect(AttributeType.multiSelect.hasValues, isTrue);
      });

      test('text no tiene valores', () {
        expect(AttributeType.text.hasValues, isFalse);
      });

      test('number no tiene valores', () {
        expect(AttributeType.number.hasValues, isFalse);
      });

      test('boolean no tiene valores', () {
        expect(AttributeType.boolean.hasValues, isFalse);
      });
    });
  });
}
