import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class CreateBookingRequested extends BookingEvent {
  final int flightId;
  final int passengersCount;
  final List<Map<String, dynamic>> passengers;
  const CreateBookingRequested({
    required this.flightId,
    required this.passengersCount,
    required this.passengers,
  });
}

class GetMyBookingsRequested extends BookingEvent {}

class ProcessPaymentRequested extends BookingEvent {
  final int bookingId;
  final Map<String, dynamic> cardData;
  const ProcessPaymentRequested(
      {required this.bookingId, required this.cardData});
}

class CheckInRequested extends BookingEvent {
  final int bookingId;
  const CheckInRequested(this.bookingId);
}

class CancelBookingRequested extends BookingEvent {
  final int bookingId;
  const CancelBookingRequested(this.bookingId);
}

class GetTicketDetailsRequested extends BookingEvent {
  final int bookingId;
  const GetTicketDetailsRequested(this.bookingId);
}
