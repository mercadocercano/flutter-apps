/// Endpoints de la API via Kong Gateway.
/// Todos los servicios se acceden via Kong (:8001 en dev).
abstract final class ApiEndpoints {
  // ─── IAM ───
  static const authLogin = '/iam/api/v1/auth/login';
  static const authRefresh = '/iam/api/v1/auth/refresh';
  static const authLogout = '/iam/api/v1/auth/logout';

  // ─── Onboarding ───
  static const onboardingRegister = '/onboarding/api/v1/register-user';

  // ─── PIM (Categorías) ───
  static const categories = '/pim/api/v1/categories';
  static String category(String id) => '/pim/api/v1/categories/$id';

  // ─── PIM (Marcas) ───
  static const brands = '/pim/api/v1/brands';
  static String brand(String id) => '/pim/api/v1/brands/$id';

  // ─── PIM (Catálogo) ───
  static const products = '/pim/api/v1/products';
  static String product(String id) => '/pim/api/v1/products/$id';
  static String productVariants(String id) => '/pim/api/v1/products/$id/variants';
  static const productsByCriteria = '/pim/api/v1/products/criteria';

  // ─── Sales (Ventas POS) ───
  static const posSales = '/sales/api/v1/sales/pos';
  static String posSale(String id) => '/sales/api/v1/sales/pos/$id';

  /// PDF A4 del comprobante (lo genera el backend — E18 Tramo C).
  static String posSalePdf(String id) => '/sales/api/v1/sales/pos/$id/pdf';

  // ─── Stock ───
  static const stockEntries = '/stock/api/v1/stock-entries';
  static const stockAvailability = '/stock/api/v1/availability';

  // ─── Global Catalog ───
  static const globalProducts = '/pim/api/v1/global-catalog/products';
  static const enrichmentQueue = '/pim/api/v1/global-catalog/enrichment-queue';

  // ─── Business Types (PIM) ───
  static const businessTypes = '/pim/api/v1/business-types';

  // ─── Quickstart ───
  static const quickstartTemplates = '/pim/api/v1/quickstart/templates';
  static const quickstartApply = '/pim/api/v1/quickstart/apply';

  // ─── Tenant Config ───
  static String tenantConfig(String key) =>
      '/tenant-service/api/v1/tenant/config/$key';
  static const tenantConfigBase = '/tenant-service/api/v1/tenant/config';
}
