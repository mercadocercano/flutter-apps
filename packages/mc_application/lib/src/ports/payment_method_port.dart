import 'package:mc_domain/mc_domain.dart';

/// Puerto de medios de pago.
abstract interface class PaymentMethodPort {
  Future<List<PaymentMethod>> listPaymentMethods();
}
