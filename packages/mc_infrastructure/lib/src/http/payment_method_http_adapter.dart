import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'mc_http_client.dart';

/// Adapter HTTP para medios de pago — habla con payment-method-service via Kong.
class PaymentMethodHttpAdapter implements PaymentMethodPort {
  final McHttpClient _client;

  PaymentMethodHttpAdapter(this._client);

  @override
  Future<List<PaymentMethod>> listPaymentMethods() async {
    final response =
        await _client.get('/payment-method/api/v1/payment-methods');
    final data = response.data as Map<String, dynamic>? ?? {};
    final items =
        data['items'] as List? ?? data['payment_methods'] as List? ?? [];
    return items
        .map((json) => _map(json as Map<String, dynamic>))
        .toList();
  }

  PaymentMethod _map(Map<String, dynamic> json) => PaymentMethod(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isGlobal: json['is_global'] == true,
      );
}
