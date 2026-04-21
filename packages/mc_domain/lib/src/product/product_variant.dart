import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../common/money.dart';
import '../common/sku.dart';

/// Estado de una variante.
enum VariantStatus { active, inactive, discontinued, deleted }

/// Variante de producto — la unidad vendible real.
/// El comerciante ve esto como "presentación" o "tamaño".
class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String name;
  final Sku? sku;
  final VariantStatus status;
  final bool isDefault;
  final int sortOrder;
  final Money price;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.status = VariantStatus.active,
    this.isDefault = false,
    this.sortOrder = 0,
    this.price = Money.zero,
    this.stock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariant.create({
    required String productId,
    required String name,
    Sku? sku,
    Money price = Money.zero,
    bool isDefault = false,
  }) {
    if (name.length < 2 || name.length > 255) {
      throw ArgumentError('Nombre de variante debe tener 2-255 caracteres');
    }
    final now = DateTime.now();
    return ProductVariant(
      id: const Uuid().v4(),
      productId: productId,
      name: name,
      sku: sku,
      price: price,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isActive => status == VariantStatus.active;
  bool get hasPrice => price.isPositive;

  ProductVariant copyWith({
    String? name,
    Sku? sku,
    VariantStatus? status,
    bool? isDefault,
    Money? price,
    int? stock,
  }) {
    return ProductVariant(
      id: id,
      productId: productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
