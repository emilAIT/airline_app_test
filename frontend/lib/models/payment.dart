enum PaymentMethod { card, applePay, googlePay }
enum PaymentStatus { pending, paid, failed }

class Payment {
  final int id;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      method: _parseMethod(json['method']),
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static PaymentMethod _parseMethod(String value) {
    switch (value) {
      case 'APPLE_PAY':
        return PaymentMethod.applePay;
      case 'GOOGLE_PAY':
        return PaymentMethod.googlePay;
      default:
        return PaymentMethod.card;
    }
  }

  static PaymentStatus _parseStatus(String value) {
    switch (value) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'FAILED':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}