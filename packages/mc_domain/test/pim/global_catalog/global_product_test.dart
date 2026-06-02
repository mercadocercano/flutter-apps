import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

GlobalProduct buildProduct({
  String id = 'prod-1',
  String name = 'Tornillo M6x20',
  String sku = 'TORN-M6-20',
  String? barcode = '7701234567890',
  String? description,
  String? imageUrl,
  List<String> businessTypeIds = const ['ferreteria'],
  String? categoryId = 'cat-1',
  Map<String, dynamic> attributes = const {},
  bool isVerified = false,
  DateTime? verifiedAt,
}) {
  final now = DateTime(2024, 6, 15);
  return GlobalProduct(
    id: id,
    name: name,
    sku: sku,
    barcode: barcode,
    description: description,
    imageUrl: imageUrl,
    businessTypeIds: businessTypeIds,
    categoryId: categoryId,
    attributes: attributes,
    isVerified: isVerified,
    verifiedAt: verifiedAt,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GlobalProduct entity', () {
    test('construye correctamente con campos obligatorios', () {
      final product = buildProduct();
      expect(product.id, 'prod-1');
      expect(product.name, 'Tornillo M6x20');
      expect(product.sku, 'TORN-M6-20');
      expect(product.isVerified, isFalse);
      expect(product.businessTypeIds, ['ferreteria']);
    });

    test('campos opcionales son null por defecto cuando no se proveen', () {
      final now = DateTime(2024, 6, 15);
      final product = GlobalProduct(
        id: 'prod-min',
        name: 'Mínimo',
        sku: 'MIN-01',
        createdAt: now,
        updatedAt: now,
      );
      expect(product.barcode, isNull);
      expect(product.description, isNull);
      expect(product.imageUrl, isNull);
      expect(product.categoryId, isNull);
      expect(product.verifiedAt, isNull);
      expect(product.businessTypeIds, isEmpty);
      expect(product.attributes, isEmpty);
    });

    test('isVerified es false por defecto', () {
      final product = buildProduct(isVerified: false);
      expect(product.isVerified, isFalse);
    });

    test('isVerified puede ser true cuando se provee', () {
      final verifiedAt = DateTime(2024, 7, 1);
      final product = buildProduct(isVerified: true, verifiedAt: verifiedAt);
      expect(product.isVerified, isTrue);
      expect(product.verifiedAt, verifiedAt);
    });

    test('igualdad por valor (Equatable)', () {
      final p1 = buildProduct();
      final p2 = buildProduct();
      expect(p1, equals(p2));
    });

    test('distintos ids generan entidades distintas', () {
      final p1 = buildProduct(id: 'prod-1');
      final p2 = buildProduct(id: 'prod-2');
      expect(p1, isNot(equals(p2)));
    });

    test('distinto sku genera entidades distintas', () {
      final p1 = buildProduct(sku: 'SKU-A');
      final p2 = buildProduct(sku: 'SKU-B');
      expect(p1, isNot(equals(p2)));
    });

    test('copyWith cambia solo los campos indicados', () {
      final original = buildProduct(name: 'Original', isVerified: false);
      final updated = original.copyWith(name: 'Actualizado', isVerified: true);
      expect(updated.name, 'Actualizado');
      expect(updated.isVerified, isTrue);
      expect(updated.id, original.id);
      expect(updated.sku, original.sku);
    });

    test('copyWith sin argumentos retorna entidad equivalente', () {
      final original = buildProduct();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('construye con todos los campos opcionales', () {
      final now = DateTime(2024, 6, 15);
      final verifiedAt = DateTime(2024, 7, 1);
      final product = GlobalProduct(
        id: 'full-prod',
        name: 'Producto Completo',
        sku: 'FULL-001',
        barcode: '1234567890123',
        description: 'Descripción detallada del producto',
        imageUrl: 'https://cdn.example.com/product.jpg',
        businessTypeIds: ['ferreteria', 'construccion'],
        categoryId: 'cat-herramientas',
        attributes: {'material': 'acero', 'diametro_mm': 6},
        isVerified: true,
        verifiedAt: verifiedAt,
        createdAt: now,
        updatedAt: now,
      );
      expect(product.barcode, '1234567890123');
      expect(product.description, 'Descripción detallada del producto');
      expect(product.imageUrl, 'https://cdn.example.com/product.jpg');
      expect(product.businessTypeIds, ['ferreteria', 'construccion']);
      expect(product.categoryId, 'cat-herramientas');
      expect(product.attributes['material'], 'acero');
      expect(product.attributes['diametro_mm'], 6);
      expect(product.isVerified, isTrue);
      expect(product.verifiedAt, verifiedAt);
    });

    test('businessTypeIds vacío por defecto', () {
      final now = DateTime(2024, 6, 15);
      final product = GlobalProduct(
        id: 'p',
        name: 'P',
        sku: 'P-01',
        createdAt: now,
        updatedAt: now,
      );
      expect(product.businessTypeIds, isEmpty);
    });

    test('attributes vacío por defecto', () {
      final now = DateTime(2024, 6, 15);
      final product = GlobalProduct(
        id: 'p',
        name: 'P',
        sku: 'P-01',
        createdAt: now,
        updatedAt: now,
      );
      expect(product.attributes, isEmpty);
    });
  });
}
