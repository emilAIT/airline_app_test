import 'package:equatable/equatable.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';

class Booking extends Equatable {
  final int id;
  final int userId;
  final int flightId;
  final String bookingReference;
  final String status;
  final double totalPrice;
  final int passengersCount;
  final DateTime createdAt;
  final Flight? flight;

  const Booking({
    required this.id,
    required this.userId,
    required this.flightId,
    required this.bookingReference,
    required this.status,
    required this.totalPrice,
    required this.passengersCount,
    required this.createdAt,
    this.flight,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
    id, userId, flightId, bookingReference, status, totalPrice, passengersCount, createdAt, flight
  ];
}
