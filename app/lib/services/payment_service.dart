import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;
  
  PaymentService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<PaymentPublic>> getMyPayments() async {
    try {
      final response = await _apiService.get(
        '/payments/me',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = PaymentsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get payments error: $e');
    }
  }

  Future<List<PaymentPublic>> getPaymentsByBooking(String bookingId) async {
    try {
      final response = await _apiService.get(
        '/payments/booking/$bookingId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = PaymentsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get payments error: $e');
    }
  }

  Future<PaymentPublic> getPayment(String paymentId) async {
    try {
      final response = await _apiService.get(
        '/payments/$paymentId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return PaymentPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get payment error: $e');
    }
  }

  Future<PaymentPublic> createPayment({
    required String bookingId,
    required PaymentMethod method,
  }) async {
    try {
      // Generate idempotency key
      final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      
      final headers = <String, String>{
        'Idempotency-Key': idempotencyKey,
      };

      final defaultHeaders = await _apiService.getHeaders(requiresAuth: true);
      defaultHeaders.addAll(headers);
      
      // Use PaymentCreate model for proper serialization
      final paymentCreate = PaymentCreate(
        bookingId: bookingId,
        method: method,
        idempotencyKey: idempotencyKey,
      );
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payments'),
        headers: defaultHeaders,
        body: jsonEncode(paymentCreate.toJson()),
      );

      if (response.statusCode == 200) {
        return PaymentPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create payment error: $e');
    }
  }

  Future<PaymentPublic> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    try {
      // Convert enum to uppercase string (PAID, PENDING, FAILED)
      final statusString = status.name.toUpperCase();
      
      final response = await _apiService.patch(
        '/payments/$paymentId/status',
        queryParams: {
          'status': statusString,
          'args': '',
          'kwargs': '',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return PaymentPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update payment status error: $e');
    }
  }

  Future<List<PaymentPublic>> getAllPayments({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/payments/',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
          'args': '',
          'kwargs': '',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = PaymentsPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get all payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get all payments error: $e');
    }
  }
}
