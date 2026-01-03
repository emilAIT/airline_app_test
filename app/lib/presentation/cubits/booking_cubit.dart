import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();
  
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingInitiated extends BookingState {
  final Booking booking;
  const BookingInitiated(this.booking);
  
  @override
  List<Object?> get props => [booking];
}

class BookingConfirmed extends BookingState {
  final Booking booking;
  const BookingConfirmed(this.booking);
  
  @override
  List<Object?> get props => [booking];
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;

  BookingCubit(this._bookingRepository) : super(BookingInitial());

  Future<void> initiateBooking(int flightId, List<Map<String, dynamic>> passengerProfiles) async {
    emit(BookingLoading());
    try {
      final booking = await _bookingRepository.initiateBooking(flightId, passengerProfiles);
      emit(BookingInitiated(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> confirmBooking(int bookingId, Map<String, dynamic> paymentData) async {
    emit(BookingLoading());
    try {
      // Extract payment_method from paymentData
      final paymentMethod = paymentData['payment_method'] as String? ?? 'CARD';
      final booking = await _bookingRepository.confirmBooking(bookingId, paymentMethod);
      emit(BookingConfirmed(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
