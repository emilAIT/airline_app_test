enum BookingStatus {
  created,
  confirmed,
  expired,
  completed,
  cancelled,
  refunded;

  String get name => toString().split('.').last.toUpperCase();
}

class Booking {
  final int id;
  final String pnr;
  final BookingStatus status;
  final DateTime? holdUntil;
  final DateTime createdAt;
  final Map<String, dynamic> flight;
  final List<dynamic> tickets;
  final Map<String, dynamic>? payment;

  Booking({
    required this.id,
    required this.pnr,
    required this.status,
    this.holdUntil,
    required this.createdAt,
    required this.flight,
    required this.tickets,
    this.payment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      pnr: json['pnr'],
      status: _parseStatus(json['status']),
      holdUntil: json['hold_until'] != null 
          ? DateTime.parse(json['hold_until']).toLocal() 
          : null,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      flight: json['flight'] ?? {},
      tickets: json['tickets'] ?? [],
      payment: json['payment'],
    );
  }

  static BookingStatus _parseStatus(String statusStr) {
    try {
      return BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () => BookingStatus.created,
      );
    } catch (_) {
      return BookingStatus.created;
    }
  }

  bool get isExpired {
    if (holdUntil == null) return false;
    return DateTime.now().isAfter(holdUntil!);
  }
  
  // Helper to get total price if available in flight/tickets
  double get totalPrice {
    final basePrice = (flight['base_price'] as num?)?.toDouble() ?? 0.0;
    return basePrice * tickets.length;
  }
}
