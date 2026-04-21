import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../common/tenant_id.dart';
import 'product_status.dart';
import 'product_variant.dart';

/// Producto — contenedor de variantes. La variante es lo que se vende.
class Product extends Equatable {
  final String id;
  final TenantId tenantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? categoryName;
  final String? brandName;
  final ProductStatus status;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryName,
    this.brandName,
    this.status = ProductStatus.draft,
    this.variants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear producto nuevo con variante por defecto.
  factory Product.create({
    required TenantId tenantId,
    required String name,
    String? description,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Nombre de producto es obligatorio');
    }
    final id = const Uuid().v4();
    final now = DateTime.now();
    final defaultVariant = ProductVariant.create(
      productId: id,
      name: name,
      isDefault: true,
    );
    return Product(
      id: id,
      tenantId: tenantId,
      name: name,
      description: description,
      variants: [defaultVariant],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Queries ───

  ProductVariant? get defaultVariant =>
      variants.where((v) => v.isDefault).firstOrNull;

  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  bool get canActivate =>
      name.isNotEmpty &&
      variants.isNotEmpty &&
      variants.any((v) => v.hasPrice);

  bool get isSellable => status.isSellable;

  // ─── Commands ───

  Product activate() {
    if (!canActivate) {
      throw StateError(
        'No se puede activar: necesita nombre, variantes y al menos una con precio',
      );
    }
    return _transitionTo(ProductStatus.active);
  }

  Product deactivate() => _transitionTo(ProductStatus.inactive);

  Product addVariant(ProductVariant variant) {
    return copyWith(variants: [...variants, variant]);
  }

  Product updateVariant(String variantId, ProductVariant updated) {
    return copyWith(
      variants: variants
          .map((v) => v.id == variantId ? updated : v)
          .toList(),
    );
  }

  Product _transitionTo(ProductStatus newStatus) {
    if (!status.canTransitionTo(newStatus)) {
      throw StateError(
        'Transición inválida: $status → $newStatus',
      );
    }
    return copyWith(status: newStatus);
  }

  Product copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? categoryName,
    String? brandName,
    ProductStatus? status,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      status: status ?? this.status,
      variants: variants ?? this.variants,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
