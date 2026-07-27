import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

/// Convierte un [SaleReceipt] del dominio en el [ReceiptData] que entiende el
/// [PrinterPort]. Mantiene al dominio ignorante del contrato de hardware.
ReceiptData receiptDataFromSale(SaleReceipt sale, {required String storeName}) {
  return ReceiptData(
    storeName: storeName,
    items: sale.items
        .map((item) => ReceiptItem(
              name: item.productName,
              quantity: item.quantity,
              unitPrice: item.unitPrice.amount,
              subtotal: item.subtotal.amount,
            ))
        .toList(),
    total: sale.finalAmount.amount,
    discount: sale.hasDiscount ? sale.discount.amount : null,
    paid: sale.amountPaid.amount,
    change: sale.change.amount,
    date: sale.createdAt,
  );
}
