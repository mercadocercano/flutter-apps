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

// PIM — Taxonomy (admin marketplace, S009)
export 'src/pim/taxonomy/marketplace_category.dart';
export 'src/pim/taxonomy/category_tree.dart';
export 'src/pim/taxonomy/taxonomy_repository.dart';
export 'src/pim/taxonomy/category_params.dart';

// PIM — Global Catalog (admin marketplace, S010)
export 'src/pim/global_catalog/global_product.dart';
export 'src/pim/global_catalog/bulk_import_result.dart';
export 'src/pim/global_catalog/global_product_repository.dart';

// PIM — Attributes (admin marketplace, S011)
export 'src/pim/attributes/attribute_type.dart';
export 'src/pim/attributes/attribute_value.dart';
export 'src/pim/attributes/marketplace_attribute.dart';
export 'src/pim/attributes/marketplace_attribute_repository.dart';

// PIM — Quickstart (admin marketplace, S012)
export 'src/pim/quickstart/business_type.dart';
export 'src/pim/quickstart/business_type_template.dart';
export 'src/pim/quickstart/template_analytics.dart';
export 'src/pim/quickstart/quickstart_repository.dart';

// Web Data domain (S013)
export 'src/webdata/web_source_status.dart';
export 'src/webdata/web_source.dart';
export 'src/webdata/web_job_status.dart';
export 'src/webdata/web_job.dart';
export 'src/webdata/price_point.dart';
export 'src/webdata/web_product.dart';
export 'src/webdata/web_data_dashboard_stats.dart';
export 'src/webdata/web_data_repository.dart';

// IAM domain
export 'src/iam/paginated_result.dart';
export 'src/iam/tenant.dart';
export 'src/iam/role.dart';
export 'src/iam/plan.dart';
export 'src/iam/repositories.dart';
