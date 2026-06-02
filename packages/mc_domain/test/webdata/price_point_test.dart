import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

PricePoint buildPricePoint({
  DateTime? date,
  double price = 100.0,
  double? variationPercent,
}) {
  return PricePoint(
    date: date ?? DateTime(2026, 1, 15),
    price: price,
    variationPercent: variationPercent,
  );
}

void main() {
  group('PricePoint value object', () {
    test('construye correctamente con campos obligatorios', () {
      final point = buildPricePoint();
      expect(point.price, 100.0);
      expect(point.variationPercent, isNull);
    });

    test('construye con variación positiva', () {
      final point = buildPricePoint(variationPercent: 5.2);
      expect(point.variationPercent, 5.2);
    });

    test('construye con variación negativa', () {
      final point = buildPricePoint(variationPercent: -3.1);
      expect(point.variationPercent, -3.1);
    });

    test('igualdad por valor (Equatable)', () {
      final p1 = buildPricePoint(price: 99.99);
      final p2 = buildPricePoint(price: 99.99);
      expect(p1, equals(p2));
    });

    test('distintos precios generan objetos distintos', () {
      final p1 = buildPricePoint(price: 100.0);
      final p2 = buildPricePoint(price: 200.0);
      expect(p1, isNot(equals(p2)));
    });

    group('isPriceIncrease', () {
      test('true cuando variationPercent es positivo', () {
        final point = buildPricePoint(variationPercent: 2.5);
        expect(point.isPriceIncrease, isTrue);
      });

      test('false cuando variationPercent es negativo', () {
        final point = buildPricePoint(variationPercent: -1.0);
        expect(point.isPriceIncrease, isFalse);
      });

      test('false cuando variationPercent es null', () {
        final point = buildPricePoint(variationPercent: null);
        expect(point.isPriceIncrease, isFalse);
      });

      test('false cuando variationPercent es exactamente cero', () {
        final point = buildPricePoint(variationPercent: 0.0);
        expect(point.isPriceIncrease, isFalse);
      });
    });

    group('isPriceDecrease', () {
      test('true cuando variationPercent es negativo', () {
        final point = buildPricePoint(variationPercent: -5.0);
        expect(point.isPriceDecrease, isTrue);
      });

      test('false cuando variationPercent es positivo', () {
        final point = buildPricePoint(variationPercent: 3.0);
        expect(point.isPriceDecrease, isFalse);
      });

      test('false cuando variationPercent es null', () {
        final point = buildPricePoint(variationPercent: null);
        expect(point.isPriceDecrease, isFalse);
      });

      test('false cuando variationPercent es exactamente cero', () {
        final point = buildPricePoint(variationPercent: 0.0);
        expect(point.isPriceDecrease, isFalse);
      });
    });

    test('props incluye date, price y variationPercent', () {
      final date = DateTime(2026, 3, 1);
      final point = PricePoint(date: date, price: 150.0, variationPercent: 5.0);
      expect(point.props, containsAll([date, 150.0, 5.0]));
    });

    test('distintas fechas generan objetos distintos', () {
      final p1 = buildPricePoint(date: DateTime(2026, 1, 1));
      final p2 = buildPricePoint(date: DateTime(2026, 6, 1));
      expect(p1, isNot(equals(p2)));
    });
  });
}
