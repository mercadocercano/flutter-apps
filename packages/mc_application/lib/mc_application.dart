/// Use cases y ports de Mercado Cercano.
library;

// IAM use cases
export 'src/iam/tenants/get_tenants_use_case.dart';
export 'src/iam/tenants/get_tenant_use_case.dart';
export 'src/iam/tenants/create_tenant_use_case.dart';
export 'src/iam/tenants/update_tenant_use_case.dart';
export 'src/iam/tenants/delete_tenant_use_case.dart';
export 'src/iam/tenants/toggle_tenant_status_use_case.dart';
export 'src/iam/roles/get_roles_use_case.dart';
export 'src/iam/roles/get_role_use_case.dart';
export 'src/iam/roles/create_role_use_case.dart';
export 'src/iam/roles/update_role_use_case.dart';
export 'src/iam/roles/delete_role_use_case.dart';
export 'src/iam/plans/get_plans_use_case.dart';
export 'src/iam/plans/get_plan_use_case.dart';
export 'src/iam/plans/create_plan_use_case.dart';
export 'src/iam/plans/update_plan_use_case.dart';
export 'src/iam/plans/delete_plan_use_case.dart';

// PIM — Taxonomy use cases (S009)
export 'src/pim/taxonomy/get_category_tree_use_case.dart';
export 'src/pim/taxonomy/get_categories_use_case.dart';
export 'src/pim/taxonomy/get_category_use_case.dart';
export 'src/pim/taxonomy/create_category_use_case.dart';
export 'src/pim/taxonomy/update_category_use_case.dart';
export 'src/pim/taxonomy/delete_category_use_case.dart';

// PIM — Global Catalog use cases (S010)
export 'src/pim/global_catalog/list_global_products_use_case.dart';
export 'src/pim/global_catalog/get_global_product_use_case.dart';
export 'src/pim/global_catalog/create_global_product_use_case.dart';
export 'src/pim/global_catalog/update_global_product_use_case.dart';
export 'src/pim/global_catalog/delete_global_product_use_case.dart';
export 'src/pim/global_catalog/verify_global_product_use_case.dart';
export 'src/pim/global_catalog/unverify_global_product_use_case.dart';
export 'src/pim/global_catalog/bulk_import_global_products_use_case.dart';

// PIM — Quickstart use cases (S012)
export 'src/pim/quickstart/list_business_types_use_case.dart';
export 'src/pim/quickstart/get_business_type_use_case.dart';
export 'src/pim/quickstart/create_business_type_use_case.dart';
export 'src/pim/quickstart/update_business_type_use_case.dart';
export 'src/pim/quickstart/delete_business_type_use_case.dart';
export 'src/pim/quickstart/activate_business_type_use_case.dart';
export 'src/pim/quickstart/deactivate_business_type_use_case.dart';

// PIM — Quickstart Templates use cases (S012-T003)
export 'src/pim/quickstart/templates/list_templates_use_case.dart';
export 'src/pim/quickstart/templates/get_template_use_case.dart';
export 'src/pim/quickstart/templates/create_template_use_case.dart';
export 'src/pim/quickstart/templates/update_template_use_case.dart';
export 'src/pim/quickstart/templates/delete_template_use_case.dart';
export 'src/pim/quickstart/templates/duplicate_template_use_case.dart';
export 'src/pim/quickstart/templates/get_template_analytics_use_case.dart';
export 'src/pim/quickstart/templates/generate_template_with_ai_use_case.dart';

// PIM — Attributes use cases (S011)
export 'src/pim/attributes/list_marketplace_attributes_use_case.dart';
export 'src/pim/attributes/get_marketplace_attribute_use_case.dart';
export 'src/pim/attributes/create_marketplace_attribute_use_case.dart';
export 'src/pim/attributes/update_marketplace_attribute_use_case.dart';
export 'src/pim/attributes/delete_marketplace_attribute_use_case.dart';
export 'src/pim/attributes/list_attribute_values_use_case.dart';
export 'src/pim/attributes/create_attribute_value_use_case.dart';
export 'src/pim/attributes/update_attribute_value_use_case.dart';
export 'src/pim/attributes/delete_attribute_value_use_case.dart';

// PIM — Brands use cases (S008)
export 'src/pim/brands/get_brands_use_case.dart';
export 'src/pim/brands/get_brand_use_case.dart';
export 'src/pim/brands/create_brand_use_case.dart';
export 'src/pim/brands/update_brand_use_case.dart';
export 'src/pim/brands/delete_brand_use_case.dart';
export 'src/pim/brands/verify_brand_use_case.dart';
export 'src/pim/brands/unverify_brand_use_case.dart';
export 'src/pim/brands/validate_brand_name_use_case.dart';

// Web Data use cases (S013)
export 'src/webdata/get_dashboard_stats_use_case.dart';
export 'src/webdata/list_sources_use_case.dart';
export 'src/webdata/get_source_use_case.dart';
export 'src/webdata/create_source_use_case.dart';
export 'src/webdata/update_source_use_case.dart';
export 'src/webdata/delete_source_use_case.dart';
export 'src/webdata/trigger_source_use_case.dart';
export 'src/webdata/list_jobs_use_case.dart';
export 'src/webdata/get_job_use_case.dart';
export 'src/webdata/cancel_job_use_case.dart';
export 'src/webdata/retry_job_use_case.dart';
export 'src/webdata/list_web_products_use_case.dart';
export 'src/webdata/get_web_product_use_case.dart';
export 'src/webdata/update_web_product_use_case.dart';
export 'src/webdata/delete_web_product_use_case.dart';
export 'src/webdata/bulk_delete_web_products_use_case.dart';
export 'src/webdata/assign_business_type_use_case.dart';
export 'src/webdata/bulk_assign_business_type_use_case.dart';
export 'src/webdata/get_price_history_use_case.dart';

// Ports
export 'src/ports/auth_port.dart';
export 'src/ports/catalog_port.dart';
export 'src/ports/category_port.dart';
export 'src/ports/brand_port.dart';
export 'src/ports/quickstart_port.dart';
export 'src/ports/sale_port.dart';
export 'src/ports/stock_port.dart';
export 'src/ports/hardware_port.dart';
export 'src/ports/customer_port.dart';
export 'src/ports/payment_method_port.dart';
export 'src/ports/tenant_config_port.dart';
