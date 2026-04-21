import 'package:equatable/equatable.dart';

/// Medio de pago disponible para el tenant.
class PaymentMethod extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isGlobal;

  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.isGlobal = false,
  });

  bool get isCash => code == 'cash';
  bool get isCard => code == 'debit_card' || code == 'credit_card';
  bool get isDigital => code == 'qr' || code == 'transfer';

  @override
  List<Object?> get props => [id];
}
