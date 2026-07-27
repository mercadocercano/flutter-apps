import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_hardware/mc_hardware.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final receipt = ReceiptData(
    storeName: 'Almacén Don José',
    items: const [
      ReceiptItem(
          name: 'Yerba 1kg', quantity: 2, unitPrice: 1500, subtotal: 3000),
      ReceiptItem(name: 'Pan', quantity: 1, unitPrice: 800, subtotal: 800),
    ],
    total: 3800,
    discount: null,
    paid: 5000,
    change: 1200,
    date: DateTime(2026, 6, 17, 10, 30),
  );

  group('EscPosReceiptFormatter', () {
    test('genera bytes ESC/POS no vacíos para 58mm', () async {
      const formatter =
          EscPosReceiptFormatter(paperWidth: ThermalPaperWidth.mm58);
      final bytes = await formatter.build(receipt);
      expect(bytes, isNotEmpty);
    });

    test('genera bytes ESC/POS no vacíos para 80mm con descuento', () async {
      const formatter =
          EscPosReceiptFormatter(paperWidth: ThermalPaperWidth.mm80);
      final withDiscount = ReceiptData(
        storeName: receipt.storeName,
        items: receipt.items,
        total: 3500,
        discount: 300,
        paid: 5000,
        change: 1500,
        date: receipt.date,
      );
      final bytes = await formatter.build(withDiscount);
      expect(bytes, isNotEmpty);
    });
  });
}
