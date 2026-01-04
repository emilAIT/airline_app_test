import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/core/usecases/usecase.dart';
import 'package:ait_airlines/features/booking/domain/entities/booking.dart';
import 'package:ait_airlines/features/booking/domain/repositories/booking_repository.dart';

class CreateBookingParams {
  final int flightId;
  final int passengersCount;
  final List<Map<String, dynamic>> passengers;
  CreateBookingParams({
    required this.flightId,
    required this.passengersCount,
    required this.passengers,
  });
}

@lazySingleton
class CreateBookingUseCase implements UseCase<Booking, CreateBookingParams> {
  final BookingRepository repository;
  CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(CreateBookingParams params) {
    return repository.createBooking(
      params.flightId,
      params.passengersCount,
      passengers: params.passengers,
    );
  }
}

@lazySingleton
class GetMyBookingsUseCase implements UseCase<List<Booking>, NoParams> {
  final BookingRepository repository;
  GetMyBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Booking>>> call(NoParams params) {
    return repository.getMyBookings();
  }
}

class ProcessPaymentParams {
  final int bookingId;
  final Map<String, dynamic> cardData;
  ProcessPaymentParams({required this.bookingId, required this.cardData});
}

@lazySingleton
class ProcessPaymentUseCase implements UseCase<void, ProcessPaymentParams> {
  final BookingRepository repository;
  ProcessPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProcessPaymentParams params) {
    return repository.processPayment(params.bookingId, params.cardData);
  }
}

class CheckInParams {
  final int bookingId;
  CheckInParams({required this.bookingId});
}

@lazySingleton
class CheckInUseCase implements UseCase<Map<String, dynamic>, CheckInParams> {
  final BookingRepository repository;
  CheckInUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CheckInParams params) {
    return repository.checkIn(params.bookingId);
  }
}
