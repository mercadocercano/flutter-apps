import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

PimStats buildPimStats({
  int totalCategories = 50,
  int verifiedBrands = 80,
  int totalBrands = 100,
  int verifiedProducts = 400,
  int totalProducts = 500,
  int totalAttributes = 30,
}) {
  return PimStats(
    totalCategories: totalCategories,
    verifiedBrands: verifiedBrands,
    totalBrands: totalBrands,
    verifiedProducts: verifiedProducts,
    totalProducts: totalProducts,
    totalAttributes: totalAttributes,
  );
}

void main() {
  group('PimStats value object', () {
    test('construye correctamente con todos los campos', () {
      final stats = buildPimStats();
      expect(stats.totalCategories, 50);
      expect(stats.verifiedBrands, 80);
      expect(stats.totalBrands, 100);
      expect(stats.verifiedProducts, 400);
      expect(stats.totalProducts, 500);
      expect(stats.totalAttributes, 30);
    });

    test('igualdad por valor (Equatable)', () {
      final s1 = buildPimStats();
      final s2 = buildPimStats();
      expect(s1, equals(s2));
    });

    test('distintos totalCategories generan objetos distintos', () {
      final s1 = buildPimStats(totalCategories: 10);
      final s2 = buildPimStats(totalCategories: 20);
      expect(s1, isNot(equals(s2)));
    });

    test('props incluye todos los campos', () {
      final stats = buildPimStats();
      expect(stats.props, containsAll([50, 80, 100, 400, 500, 30]));
    });

    group('verifiedBrandsPercent', () {
      test('80 cuando 80 de 100 están verificadas', () {
        final stats = buildPimStats(verifiedBrands: 80, totalBrands: 100);
        expect(stats.verifiedBrandsPercent, 80);
      });

      test('100 cuando todas están verificadas', () {
        final stats = buildPimStats(verifiedBrands: 50, totalBrands: 50);
        expect(stats.verifiedBrandsPercent, 100);
      });

      test('0 cuando no hay marcas verificadas', () {
        final stats = buildPimStats(verifiedBrands: 0, totalBrands: 100);
        expect(stats.verifiedBrandsPercent, 0);
      });

      test('0 cuando totalBrands es cero (evita división por cero)', () {
        final stats = buildPimStats(verifiedBrands: 0, totalBrands: 0);
        expect(stats.verifiedBrandsPercent, 0);
      });

      test('redondea correctamente — 1 de 3 → 33', () {
        final stats = buildPimStats(verifiedBrands: 1, totalBrands: 3);
        expect(stats.verifiedBrandsPercent, 33);
      });
    });

    group('verifiedProductsPercent', () {
      test('80 cuando 400 de 500 están verificados', () {
        final stats = buildPimStats(verifiedProducts: 400, totalProducts: 500);
        expect(stats.verifiedProductsPercent, 80);
      });

      test('100 cuando todos están verificados', () {
        final stats = buildPimStats(verifiedProducts: 200, totalProducts: 200);
        expect(stats.verifiedProductsPercent, 100);
      });

      test('0 cuando no hay productos verificados', () {
        final stats = buildPimStats(verifiedProducts: 0, totalProducts: 500);
        expect(stats.verifiedProductsPercent, 0);
      });

      test('0 cuando totalProducts es cero (evita división por cero)', () {
        final stats = buildPimStats(verifiedProducts: 0, totalProducts: 0);
        expect(stats.verifiedProductsPercent, 0);
      });

      test('redondea correctamente — 2 de 3 → 67', () {
        final stats = buildPimStats(verifiedProducts: 2, totalProducts: 3);
        expect(stats.verifiedProductsPercent, 67);
      });
    });
  });
}
