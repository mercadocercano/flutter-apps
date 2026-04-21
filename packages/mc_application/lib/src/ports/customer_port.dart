import 'package:mc_domain/mc_domain.dart';

/// Puerto de clientes del comercio.
abstract interface class CustomerPort {
  Future<List<Customer>> listCustomers({String? search, int page = 1});
  Future<Customer> getCustomer(String id);
  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? document,
  });
  Future<Customer> getDefaultCustomer();
}
