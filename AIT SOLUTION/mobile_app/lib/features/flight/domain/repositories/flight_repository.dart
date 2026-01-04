import 'package:dartz/dartz.dart';
import 'package:ait_airlines/core/error/failures.dart';
import '../entities/flight.dart';
import '../entities/airport.dart';

abstract class FlightRepository {
  Future<Either<Failure, List<Flight>>> getFlights({
    String? departure,
    String? arrival,
    String? date,
    int? passengersCount,
  });
  Future<Either<Failure, Flight>> createFlight(Map<String, dynamic> flightData);
  Future<Either<Failure, List<Airport>>> getAirports();
  Future<Either<Failure, Airport>> createAirport(
      Map<String, dynamic> airportData);
  Future<Either<Failure, Flight>> updateFlightStatus(
      int flightId, String status);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSeatMap(int flightId);
  Future<Either<Failure, Flight>> updateGates(
      int flightId, String gateDeparture, String gateArrival);
}
