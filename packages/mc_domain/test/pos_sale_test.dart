import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  late TenantId tenantId;

  setUp(() {
    tenantId = TenantId('test-tenant-123');
  });

  group('PosSale', () {
    test('crear venta vacía', () {
      final sale = PosSale.start(tenantId: tenantId);
      expect(sale.isEmpty, isTrue);
      expect(sale.totalAmount, Money.zero);
      expect(sale.canComplete, isFalse);
    });

    test('agregar item y calcular total', () {
      final sale = PosSale.start(tenantId: tenantId).addItem(
        PosSaleItem.create(
          sku: 'COCA-500',
          productName: 'Coca-Cola 500ml',
          quantity: 2,
          unitPrice: Money.ars(2000),
        ),
      );
      expect(sale.totalItems, 2);
      expect(sale.totalAmount.amount, 4000);
    });

    test('agregar mismo SKU suma cantidad', () {
      var sale = PosSale.start(tenantId: tenantId);
      final item = PosSaleItem.create(
        sku: 'YERBA-1KG',
        productName: 'Yerba Taragüi 1kg',
        quantity: 1,
        unitPrice: Money.ars(4500),
      );
      sale = sale.addItem(item);
      sale = sale.addItem(PosSaleItem.create(
        sku: 'YERBA-1KG',
        productName: 'Yerba Taragüi 1kg',
        quantity: 2,
        unitPrice: Money.ars(4500),
      ));
      expect(sale.items.length, 1);
      expect(sale.items.first.quantity, 3);
      expect(sale.totalAmount.amount, 13500);
    });

    test('aplicar descuento', () {
      final sale = PosSale.start(tenantId: tenantId)
          .addItem(PosSaleItem.create(
            sku: 'PAN-FARGO',
            productName: 'Pan Fargo',
            quantity: 1,
            unitPrice: Money.ars(2200),
          ))
          .applyDiscount(Money.ars(200));
      expect(sale.finalAmount.amount, 2000);
    });

    test('pagar y calcular vuelto', () {
      final sale = PosSale.start(tenantId: tenantId)
          .addItem(PosSaleItem.create(
            sku: 'LECHE-1L',
            productName: 'Leche La Serenísima 1L',
            quantity: 1,
            unitPrice: Money.ars(1800),
          ))
          .pay(Money.ars(2000));
      expect(sale.canComplete, isTrue);
      expect(sale.change.amount, 200);
    });

    test('no puede completar sin pago suficiente', () {
      final sale = PosSale.start(tenantId: tenantId)
          .addItem(PosSaleItem.create(
            sku: 'FERNET-750',
            productName: 'Fernet Branca 750ml',
            quantity: 1,
            unitPrice: Money.ars(8500),
          ))
          .pay(Money.ars(5000));
      expect(sale.canComplete, isFalse);
    });

    test('remover item', () {
      var sale = PosSale.start(tenantId: tenantId);
      final item = PosSaleItem.create(
        sku: 'ITEM-1',
        productName: 'Item 1',
        quantity: 1,
        unitPrice: Money.ars(100),
      );
      sale = sale.addItem(item);
      sale = sale.removeItem(sale.items.first.id);
      expect(sale.isEmpty, isTrue);
    });
  });
}
