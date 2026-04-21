import 'package:equatable/equatable.dart';

/// Value object para representar dinero. Evita errores de punto flotante
/// usando centavos internamente.
class Money extends Equatable {
  final int _cents;
  final String currency;

  const Money._(this._cents, this.currency);

  factory Money.ars(double amount) =>
      Money._((amount * 100).round(), 'ARS');

  factory Money.fromCents(int cents, {String currency = 'ARS'}) =>
      Money._(cents, currency);

  static const zero = Money._(0, 'ARS');

  double get amount => _cents / 100;
  int get cents => _cents;
  bool get isZero => _cents == 0;
  bool get isPositive => _cents > 0;
  bool get isNegative => _cents < 0;

  Money operator +(Money other) {
    assert(currency == other.currency, 'No se pueden sumar monedas distintas');
    return Money._(_cents + other._cents, currency);
  }

  Money operator -(Money other) {
    assert(currency == other.currency, 'No se pueden restar monedas distintas');
    return Money._(_cents - other._cents, currency);
  }

  Money operator *(int quantity) =>
      Money._(_cents * quantity, currency);

  bool operator >=(Money other) => _cents >= other._cents;
  bool operator >(Money other) => _cents > other._cents;
  bool operator <(Money other) => _cents < other._cents;

  /// Formato legible: $1.500,00
  String get formatted {
    final whole = (_cents ~/ 100).toString();
    final decimal = (_cents.abs() % 100).toString().padLeft(2, '0');
    // Separador de miles con punto (formato argentino)
    final parts = <String>[];
    for (var i = whole.length; i > 0; i -= 3) {
      parts.insert(0, whole.substring(i < 3 ? 0 : i - 3, i));
    }
    return '\$${parts.join('.')},$decimal';
  }

  @override
  List<Object?> get props => [_cents, currency];

  @override
  String toString() => formatted;
}
