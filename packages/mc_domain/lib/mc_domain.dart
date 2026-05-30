library mc_domain;

// Common value objects
export 'src/common/money.dart';
export 'src/common/tenant_id.dart';
export 'src/common/sku.dart';
export 'src/common/customer.dart';
export 'src/common/payment_method.dart';

// Product domain
export 'src/product/product.dart';
export 'src/product/product_variant.dart';
export 'src/product/product_status.dart';
export 'src/product/brand.dart';
export 'src/product/category.dart';

// Sales domain
export 'src/sale/pos_sale.dart';
export 'src/sale/pos_sale_item.dart';

// PIM — Brands (admin marketplace)
export 'src/pim/brand/marketplace_brand.dart';
export 'src/pim/brand/brand_repository.dart';
export 'src/pim/brand/brand_params.dart';

// IAM domain
export 'src/iam/paginated_result.dart';
export 'src/iam/tenant.dart';
export 'src/iam/role.dart';
export 'src/iam/plan.dart';
export 'src/iam/repositories.dart';
