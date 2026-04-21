import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../common/money.dart';

/// Item de una venta POS.
class PosSaleItem extends Equatable {
  final String id;
  final String sku;
  final String productName;
  final int quantity;
  final Money unitPrice;

  const PosSaleItem({
    required this.id,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory PosSaleItem.create({
    required String sku,
    required String productName,
    required int quantity,
    required Money unitPrice,
  }) {
    if (sku.isEmpty) throw ArgumentError('SKU es obligatorio');
    if (quantity <= 0) throw ArgumentError('Cantidad debe ser mayor a 0');
    if (!unitPrice.isPositive) throw ArgumentError('Precio debe ser positivo');

    return PosSaleItem(
      id: const Uuid().v4(),
      sku: sku,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  Money get subtotal => unitPrice * quantity;

  PosSaleItem withQuantity(int newQuantity) {
    if (newQuantity <= 0) throw ArgumentError('Cantidad debe ser mayor a 0');
    return PosSaleItem(
      id: id,
      sku: sku,
      productName: productName,
      quantity: newQuantity,
      unitPrice: unitPrice,
    );
  }

  @override
  List<Object?> get props => [id];
}
