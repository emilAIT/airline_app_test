import '../../domain/entities/booking.dart';
import 'flight_model.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.ticketNumber,
    required super.seatNumber,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      seatNumber: json['seat_number'] ?? '',
    );
  }
}

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.pnr,
    required super.userId,
    required super.flightId,
    required super.status,
    super.seatHoldExpiresAt,
    required super.createdAt,
    super.flight,
    required super.tickets,
    super.passengerName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      pnr: json['pnr'] ?? '',
      userId: json['user_id'] ?? 0,
      flightId: json['flight_id'] ?? 0,
      status: BookingStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['status'] ?? 'CREATED').toString().toUpperCase(),
        orElse: () => BookingStatus.created,
      ),
      seatHoldExpiresAt: json['seat_hold_expires_at'] != null ||
              json['held_until'] != null
          ? DateTime.parse(json['seat_hold_expires_at'] ?? json['held_until'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      flight:
          json['flight'] != null ? FlightModel.fromJson(json['flight']) : null,
      tickets: (json['tickets'] as List?)
              ?.map((t) => TicketModel.fromJson(t))
              .toList() ??
          [],
      passengerName: json['passenger_name'],
    );
  }
}
