/// Endpoints de la API via Kong Gateway.
/// Todos los servicios se acceden via Kong (:8001 en dev).
abstract final class ApiEndpoints {
  // ─── IAM ───
  static const authLogin = '/iam/api/v1/auth/login';
  static const authRefresh = '/iam/api/v1/auth/refresh';
  static const authLogout = '/iam/api/v1/auth/logout';

  // ─── PIM (Catálogo) ───
  static const products = '/pim/api/v1/products';
  static String product(String id) => '/pim/api/v1/products/$id';
  static const productsByCriteria = '/pim/api/v1/products/criteria';

  // ─── Sales (Ventas POS) ───
  static const posSales = '/sales/api/v1/pos/sales';
  static String posSale(String id) => '/sales/api/v1/pos/sales/$id';

  // ─── Stock ───
  static const stockEntries = '/stock/api/v1/stock-entries';
  static const stockBySku = '/stock/api/v1/stock/sku';
  static String stockForSku(String sku) => '/stock/api/v1/stock/sku/$sku';

  // ─── Global Catalog ───
  static const globalProducts = '/pim/api/v1/global-catalog/products';
  static const enrichmentQueue = '/pim/api/v1/global-catalog/enrichment-queue';
}
