/// Bounded contexts, entities, value objects y business rules de Mercado Cercano.
/// Puro Dart, sin dependencias de Flutter.
library;

// Common value objects
export 'src/common/money.dart';
export 'src/common/tenant_id.dart';
export 'src/common/sku.dart';
export 'src/common/customer.dart';
export 'src/common/payment_method.dart';

// Product bounded context
export 'src/product/product.dart';
export 'src/product/product_variant.dart';
export 'src/product/product_status.dart';

// Sale bounded context
export 'src/sale/pos_sale.dart';
export 'src/sale/pos_sale_item.dart';
