import 'package:mc_infrastructure/mc_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('ApiEndpoints', () {
    test('TestApiEndpoints_StaticConstants_CorrectPaths', () {
      expect(ApiEndpoints.authLogin, '/iam/api/v1/auth/login');
      expect(ApiEndpoints.authRefresh, '/iam/api/v1/auth/refresh');
      expect(ApiEndpoints.authLogout, '/iam/api/v1/auth/logout');
      expect(ApiEndpoints.categories, '/pim/api/v1/categories');
      expect(ApiEndpoints.brands, '/pim/api/v1/brands');
      expect(ApiEndpoints.products, '/pim/api/v1/products');
      expect(ApiEndpoints.posSales, '/sales/api/v1/sales/pos');
    });

    test('TestApiEndpoints_Category_BuildsPathWithId', () {
      expect(ApiEndpoints.category('cat-123'), '/pim/api/v1/categories/cat-123');
    });

    test('TestApiEndpoints_Brand_BuildsPathWithId', () {
      expect(ApiEndpoints.brand('brand-abc'), '/pim/api/v1/brands/brand-abc');
    });

    test('TestApiEndpoints_Product_BuildsPathWithId', () {
      expect(ApiEndpoints.product('prod-xyz'), '/pim/api/v1/products/prod-xyz');
    });

    test('TestApiEndpoints_ProductVariants_BuildsPathWithId', () {
      expect(
        ApiEndpoints.productVariants('prod-xyz'),
        '/pim/api/v1/products/prod-xyz/variants',
      );
    });

    test('TestApiEndpoints_PosSale_BuildsPathWithId', () {
      expect(ApiEndpoints.posSale('sale-001'), '/sales/api/v1/sales/pos/sale-001');
    });
  });
}
