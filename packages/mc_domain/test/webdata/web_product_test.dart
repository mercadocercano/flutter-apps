import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

WebProduct buildWebProduct({
  String id = 'prod-1',
  String sourceId = 'src-1',
  String name = 'Martillo 500g',
  double price = 1500.0,
  String? imageUrl,
  String url = 'https://example.com/martillo',
  String? businessTypeId,
  DateTime? scrapedAt,
  List<PricePoint> priceHistory = const [],
}) {
  return WebProduct(
    id: id,
    sourceId: sourceId,
    name: name,
    price: price,
    imageUrl: imageUrl,
    url: url,
    businessTypeId: businessTypeId,
    scrapedAt: scrapedAt ?? DateTime(2026, 1, 15, 9, 0),
    priceHistory: priceHistory,
  );
}

PricePoint buildPricePoint({
  DateTime? date,
  double price = 1500.0,
  double? variationPercent,
}) {
  return PricePoint(
    date: date ?? DateTime(2026, 1, 15),
    price: price,
    variationPercent: variationPercent,
  );
}

void main() {
  group('WebProduct entity', () {
    test('construye correctamente con campos obligatorios', () {
      final product = buildWebProduct();
      expect(product.id, 'prod-1');
      expect(product.sourceId, 'src-1');
      expect(product.name, 'Martillo 500g');
      expect(product.price, 1500.0);
      expect(product.url, 'https://example.com/martillo');
      expect(product.imageUrl, isNull);
      expect(product.businessTypeId, isNull);
      expect(product.priceHistory, isEmpty);
    });

    test('construye con todos los campos opcionales', () {
      final priceHistory = [
        buildPricePoint(price: 1200.0),
        buildPricePoint(price: 1500.0, variationPercent: 25.0),
      ];
      final product = buildWebProduct(
        imageUrl: 'https://img.example.com/martillo.jpg',
        businessTypeId: 'bt-ferreteria',
        priceHistory: priceHistory,
      );
      expect(product.imageUrl, 'https://img.example.com/martillo.jpg');
      expect(product.businessTypeId, 'bt-ferreteria');
      expect(product.priceHistory, hasLength(2));
    });

    test('igualdad por valor (Equatable)', () {
      final p1 = buildWebProduct();
      final p2 = buildWebProduct();
      expect(p1, equals(p2));
    });

    test('distintos ids generan entidades distintas', () {
      final p1 = buildWebProduct(id: 'prod-1');
      final p2 = buildWebProduct(id: 'prod-2');
      expect(p1, isNot(equals(p2)));
    });

    group('hasBusinessType', () {
      test('false cuando businessTypeId es null', () {
        final product = buildWebProduct(businessTypeId: null);
        expect(product.hasBusinessType, isFalse);
      });

      test('true cuando businessTypeId está asignado', () {
        final product = buildWebProduct(businessTypeId: 'bt-ferreteria');
        expect(product.hasBusinessType, isTrue);
      });
    });

    group('copyWith', () {
      test('cambia el name', () {
        final original = buildWebProduct(name: 'Martillo 500g');
        final updated = original.copyWith(name: 'Martillo 1kg');
        expect(updated.name, 'Martillo 1kg');
        expect(updated.id, original.id);
      });

      test('cambia el price', () {
        final original = buildWebProduct(price: 1500.0);
        final updated = original.copyWith(price: 1800.0);
        expect(updated.price, 1800.0);
        expect(updated.id, original.id);
      });

      test('asigna businessTypeId', () {
        final original = buildWebProduct(businessTypeId: null);
        final updated = original.copyWith(businessTypeId: 'bt-ferreteria');
        expect(updated.businessTypeId, 'bt-ferreteria');
        expect(updated.id, original.id);
        expect(updated.hasBusinessType, isTrue);
      });

      test('asigna imageUrl', () {
        final original = buildWebProduct(imageUrl: null);
        final updated = original.copyWith(imageUrl: 'https://img.com/prod.jpg');
        expect(updated.imageUrl, 'https://img.com/prod.jpg');
        expect(updated.id, original.id);
      });

      test('actualiza priceHistory', () {
        final original = buildWebProduct(priceHistory: []);
        final history = [buildPricePoint(price: 1000.0)];
        final updated = original.copyWith(priceHistory: history);
        expect(updated.priceHistory, hasLength(1));
        expect(updated.id, original.id);
      });

      test('sin argumentos devuelve entidad equivalente', () {
        final original = buildWebProduct(businessTypeId: 'bt-1');
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('puede sobreescribir scrapedAt', () {
        final original = buildWebProduct();
        final newDate = DateTime(2026, 6, 1);
        final updated = original.copyWith(scrapedAt: newDate);
        expect(updated.scrapedAt, newDate);
        expect(updated.id, original.id);
      });
    });

    test('distinto price genera entidades distintas', () {
      final p1 = buildWebProduct(price: 100.0);
      final p2 = buildWebProduct(price: 200.0);
      expect(p1, isNot(equals(p2)));
    });

    test('distinto businessTypeId genera entidades distintas', () {
      final p1 = buildWebProduct(businessTypeId: 'bt-1');
      final p2 = buildWebProduct(businessTypeId: 'bt-2');
      expect(p1, isNot(equals(p2)));
    });

    test('props incluye todos los campos', () {
      final product = buildWebProduct(
        imageUrl: 'https://img.com/x.jpg',
        businessTypeId: 'bt-1',
      );
      expect(
        product.props,
        containsAll([
          product.id,
          product.sourceId,
          product.name,
          product.price,
          product.imageUrl,
          product.url,
          product.businessTypeId,
          product.scrapedAt,
          product.priceHistory,
        ]),
      );
    });
  });
}
