/// Adaptadores de infraestructura de Mercado Cercano.
library;

// Admin HTTP + Auth
export 'src/auth/admin_auth_helper.dart';
export 'src/http/admin_http_client.dart';

// HTTP
export 'src/http/mc_http_client.dart';
export 'src/http/api_endpoints.dart';
export 'src/http/auth_http_adapter.dart';
export 'src/http/catalog_http_adapter.dart';
export 'src/http/category_http_adapter.dart';
export 'src/http/brand_http_adapter.dart';
export 'src/http/sale_http_adapter.dart';
export 'src/http/stock_http_adapter.dart';
export 'src/http/quickstart_http_adapter.dart';
export 'src/http/payment_method_http_adapter.dart';
export 'src/http/tenant_config_http_adapter.dart';

// PIM HTTP repositories (S008)
export 'src/pim/brands/brand_mappers.dart';
export 'src/pim/brands/marketplace_brand_repository_impl.dart';

// IAM HTTP repositories
export 'src/iam/iam_mappers.dart';
export 'src/iam/tenant_repository_impl.dart';
export 'src/iam/role_repository_impl.dart';
export 'src/iam/plan_repository_impl.dart';

// Storage
export 'src/storage/secure_session_storage.dart';
