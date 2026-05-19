/// Puerto para el flujo de quickstart (configuración inicial del comercio).
abstract interface class QuickstartPort {
  Future<List<BusinessTypeInfo>> listBusinessTypes();
  Future<List<QuickstartTemplate>> listTemplates({String? businessTypeId});
  Future<QuickstartImportResult> importFromBusinessType({
    required String businessTypeId,
  });
}

/// Tipo de negocio devuelto por el backend.
class BusinessTypeInfo {
  final String id;
  final String code;
  final String name;
  final String icon;  // nombre del icono material (ej: "store", "storefront")
  final String color; // hex: #RRGGBB
  final int sortOrder;

  const BusinessTypeInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });
}

/// Template de catálogo para un tipo de negocio.
class QuickstartTemplate {
  final String id;
  final String businessTypeId;
  final String name;
  final List<TemplateCategory> categories;
  final List<TemplateBrand> brands;
  final List<TemplateProduct> products;

  const QuickstartTemplate({
    required this.id,
    required this.businessTypeId,
    required this.name,
    required this.categories,
    required this.brands,
    required this.products,
  });
}

/// Categoría dentro de un template — el comerciante puede deseleccionar.
class TemplateCategory {
  final String id;
  final String name;
  final String slug;
  bool isSelected;

  TemplateCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.isSelected = true,
  });
}

/// Marca dentro de un template — el comerciante puede deseleccionar.
class TemplateBrand {
  final String name;
  bool isSelected;

  TemplateBrand({
    required this.name,
    this.isSelected = true,
  });
}

/// Producto dentro de un template.
class TemplateProduct {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String brandName;
  final String sku;
  final double price;
  bool isSelected;

  TemplateProduct({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.brandName,
    required this.sku,
    required this.price,
    this.isSelected = true,
  });
}

/// Producto importado como resultado del quickstart.
class ImportedProduct {
  final String name;
  final String sku;

  const ImportedProduct({
    required this.name,
    required this.sku,
  });
}

/// Resultado de la importación de catálogo.
class QuickstartImportResult {
  final int productsImported;
  final int categoriesCreated;
  final int brandsImported;
  final List<ImportedProduct> products;

  const QuickstartImportResult({
    required this.productsImported,
    required this.categoriesCreated,
    required this.brandsImported,
    required this.products,
  });
}
