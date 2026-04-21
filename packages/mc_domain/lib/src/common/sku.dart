import 'package:equatable/equatable.dart';

/// Value object para SKU de producto/variante.
/// Formato: 3-50 caracteres, A-Z0-9_-
class Sku extends Equatable {
  static final _pattern = RegExp(r'^[A-Za-z0-9_-]{3,50}$');

  final String value;

  Sku(this.value) {
    if (!_pattern.hasMatch(value)) {
      throw ArgumentError(
        'SKU inválido: "$value". Debe tener 3-50 caracteres alfanuméricos, guiones o guiones bajos.',
      );
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
