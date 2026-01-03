import 'package:dartz/dartz.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/booking/domain/entities/booking.dart';

abstract class BookingRepository {
  Future<Either<Failure, Booking>> createBooking(
    int flightId,
    int passengersCount, {
    List<Map<String, dynamic>>? passengers,
  });
  Future<Either<Failure, List<Booking>>> getMyBookings();
  Future<Either<Failure, void>> processPayment(
      int bookingId, Map<String, dynamic> cardData);
  Future<Either<Failure, Map<String, dynamic>>> checkIn(int bookingId);
  Future<Either<Failure, Map<String, dynamic>>> cancelBooking(int bookingId);
  Future<Either<Failure, Map<String, dynamic>>> getTicketDetails(int bookingId);
}
