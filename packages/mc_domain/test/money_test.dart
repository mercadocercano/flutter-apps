import 'package:mc_domain/mc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('crear desde pesos argentinos', () {
      final price = Money.ars(1500.50);
      expect(price.amount, 1500.50);
      expect(price.cents, 150050);
      expect(price.currency, 'ARS');
    });

    test('sumar dos montos', () {
      final a = Money.ars(100);
      final b = Money.ars(250.50);
      expect((a + b).amount, 350.50);
    });

    test('restar montos', () {
      final total = Money.ars(1000);
      final discount = Money.ars(150);
      expect((total - discount).amount, 850);
    });

    test('multiplicar por cantidad', () {
      final unitPrice = Money.ars(350);
      expect((unitPrice * 3).amount, 1050);
    });

    test('formato argentino', () {
      expect(Money.ars(1500).formatted, '\$1.500,00');
      expect(Money.ars(50.5).formatted, '\$50,50');
      expect(Money.zero.formatted, '\$0,00');
    });

    test('comparaciones', () {
      expect(Money.ars(100) >= Money.ars(100), isTrue);
      expect(Money.ars(200) > Money.ars(100), isTrue);
      expect(Money.ars(50) < Money.ars(100), isTrue);
    });

    test('igualdad por valor', () {
      expect(Money.ars(100) == Money.ars(100), isTrue);
      expect(Money.ars(100) == Money.ars(200), isFalse);
    });
  });
}
