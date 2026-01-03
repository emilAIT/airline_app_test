import 'package:equatable/equatable.dart';
import 'flight.dart';

enum BookingStatus {
  created,
  confirmed,
  cancelled,
}

class Ticket extends Equatable {
  final int id;
  final String ticketNumber;
  final String seatNumber;

  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.seatNumber,
  });

  @override
  List<Object?> get props => [id, ticketNumber, seatNumber];
}

class Booking extends Equatable {
  final int id;
  final String pnr;
  final int userId;
  final int flightId;
  final BookingStatus status;
  final DateTime? seatHoldExpiresAt;
  final DateTime createdAt;
  final Flight? flight;
  final List<Ticket> tickets;
  final String? passengerName;

  const Booking({
    required this.id,
    required this.pnr,
    required this.userId,
    required this.flightId,
    required this.status,
    this.seatHoldExpiresAt,
    required this.createdAt,
    this.flight,
    required this.tickets,
    this.passengerName,
  });

  bool get isHoldExpired =>
      seatHoldExpiresAt != null && DateTime.now().isAfter(seatHoldExpiresAt!);

  @override
  List<Object?> get props => [
        id,
        pnr,
        userId,
        flightId,
        status,
        seatHoldExpiresAt,
        createdAt,
        flight,
        tickets,
        passengerName,
      ];
}
