import 'enums.dart';

class Ticket {
  final int id;
  final String ticketNumber;
  final int bookingId;
  final String passengerName;
  final String passportNumber;
  final String seatNumber;
  final SeatCategory seatCategory;
  final double price;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.bookingId,
    required this.passengerName,
    required this.passportNumber,
    required this.seatNumber,
    required this.seatCategory,
    required this.price,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      ticketNumber: json['ticket_number'] as String,
      bookingId: json['booking_id'] != null ? (json['booking_id'] as num).toInt() : 0,
      passengerName: json['passenger_name'] as String,
      passportNumber: json['passport_number'] as String,
      seatNumber: json['seat_number'] as String,
      seatCategory: SeatCategory.fromJson(json['seat_category'] as String),
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'booking_id': bookingId,
      'passenger_name': passengerName,
      'passport_number': passportNumber,
      'seat_number': seatNumber,
      'seat_category': seatCategory.toJson(),
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

