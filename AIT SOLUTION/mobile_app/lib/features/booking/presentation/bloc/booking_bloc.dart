import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

@injectable
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repository;

  BookingBloc(this._repository) : super(BookingInitial()) {
    on<CreateBookingRequested>(_onCreateBookingRequested);
    on<GetMyBookingsRequested>(_onGetMyBookingsRequested);
    on<ProcessPaymentRequested>(_onProcessPaymentRequested);
    on<CheckInRequested>(_onCheckInRequested);
    on<CancelBookingRequested>(_onCancelBookingRequested);
    on<GetTicketDetailsRequested>(_onGetTicketDetailsRequested);
  }

  Future<void> _onCreateBookingRequested(
    CreateBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _repository.createBooking(
      event.flightId,
      event.passengersCount,
      passengers: event.passengers,
    );
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> _onGetMyBookingsRequested(
    GetMyBookingsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _repository.getMyBookings();
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (bookings) => emit(BookingsLoaded(bookings)),
    );
  }

  Future<void> _onProcessPaymentRequested(
    ProcessPaymentRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result =
        await _repository.processPayment(event.bookingId, event.cardData);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => emit(PaymentSuccess()),
    );
  }

  Future<void> _onCheckInRequested(
    CheckInRequested event,
    Emitter<BookingState> emit,
  ) async {
    print('DEBUG CheckInRequested: bookingId=${event.bookingId}');
    emit(BookingLoading());
    final result = await _repository.checkIn(event.bookingId);
    result.fold(
      (failure) {
        print('DEBUG CheckIn failure: ${failure.message}');
        emit(BookingError(failure.message));
      },
      (data) {
        print('DEBUG CheckIn success: $data');
        emit(CheckInSuccess(data));
      },
    );
  }

  Future<void> _onCancelBookingRequested(
    CancelBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _repository.cancelBooking(event.bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (response) => emit(BookingCancelled(response['message'] ?? 'Booking cancelled successfully')),
    );
  }

  Future<void> _onGetTicketDetailsRequested(
    GetTicketDetailsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _repository.getTicketDetails(event.bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (details) => emit(TicketDetailsLoaded(details)),
    );
  }
}
