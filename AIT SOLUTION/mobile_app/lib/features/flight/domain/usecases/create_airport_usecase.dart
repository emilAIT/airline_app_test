import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/flight/domain/entities/airport.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';

@injectable
class CreateAirportUseCase {
  final FlightRepository repository;

  CreateAirportUseCase(this.repository);

  Future<Either<Failure, Airport>> call(Map<String, dynamic> airportData) {
    return repository.createAirport(airportData);
  }
}
