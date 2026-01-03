import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingCreated extends BookingState {
  final Booking booking;
  const BookingCreated(this.booking);
  @override
  List<Object?> get props => [booking];
}

class BookingsLoaded extends BookingState {
  final List<Booking> bookings;
  const BookingsLoaded(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class PaymentSuccess extends BookingState {}

class CheckInSuccess extends BookingState {
  final Map<String, dynamic> data;
  const CheckInSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class BookingCancelled extends BookingState {
  final String message;
  const BookingCancelled(this.message);
  @override
  List<Object?> get props => [message];
}

class TicketDetailsLoaded extends BookingState {
  final Map<String, dynamic> ticketDetails;
  const TicketDetailsLoaded(this.ticketDetails);
  @override
  List<Object?> get props => [ticketDetails];
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
  @override
  List<Object?> get props => [message];
}
