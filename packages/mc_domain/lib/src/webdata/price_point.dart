import 'package:equatable/equatable.dart';

/// Value object que representa el precio de un producto en un momento dado.
///
/// Forma parte del historial de precios de un WebProduct y permite
/// visualizar la evolución del precio a lo largo del tiempo.
class PricePoint extends Equatable {
  final DateTime date;
  final double price;

  /// Variación porcentual respecto al punto anterior. Null en el primer punto.
  final double? variationPercent;

  const PricePoint({
    required this.date,
    required this.price,
    this.variationPercent,
  });

  /// Indica si el precio subió respecto al punto anterior.
  bool get isPriceIncrease => variationPercent != null && variationPercent! > 0;

  /// Indica si el precio bajó respecto al punto anterior.
  bool get isPriceDecrease => variationPercent != null && variationPercent! < 0;

  @override
  List<Object?> get props => [date, price, variationPercent];
}
