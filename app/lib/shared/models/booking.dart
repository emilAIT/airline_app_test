import 'enums.dart';
import 'flight.dart';
import 'ticket.dart';

class Booking {
  final int id;
  final String pnr;
  final int flightId;
  final int userId;
  final BookingStatus status;
  final double totalPrice;
  final DateTime createdAt;
  final Flight? flight;
  final List<Ticket>? tickets;

  Booking({
    required this.id,
    required this.pnr,
    required this.flightId,
    required this.userId,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.flight,
    this.tickets,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      pnr: json['pnr'] as String,
      flightId: json['flight_id'] != null ? (json['flight_id'] as num).toInt() : 0,
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : 0,
      status: BookingStatus.fromJson(json['status'] as String),
      totalPrice: json['total_price'] != null ? (json['total_price'] as num).toDouble() : 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      flight: json['flight'] != null
          ? Flight.fromJson(json['flight'] as Map<String, dynamic>)
          : null,
      tickets: json['tickets'] != null
          ? (json['tickets'] as List)
              .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pnr': pnr,
      'flight_id': flightId,
      'user_id': userId,
      'status': status.toJson(),
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      if (flight != null) 'flight': flight!.toJson(),
      if (tickets != null) 'tickets': tickets!.map((e) => e.toJson()).toList(),
    };
  }
}

