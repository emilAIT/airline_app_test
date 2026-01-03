import '../models/payment.dart';
import 'api_client.dart';

class PaymentsApi {
  final ApiClient client;

  PaymentsApi(this.client);

  Future<Payment> processPayment({
    required int bookingId,
    required String method,
    String? idempotencyKey,
  }) async {
    final response = await client.post('/payments/', body: {
      'booking_id': bookingId,
      'method': method,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    });
    return Payment.fromJson(response);
  }

  Future<Payment> getPayment(int bookingId) async {
    final response = await client.get('/payments/$bookingId');
    return Payment.fromJson(response);
  }
}

