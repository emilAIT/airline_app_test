import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';

@injectable
class CreateFlightUseCase {
  final FlightRepository repository;

  CreateFlightUseCase(this.repository);

  Future<Either<Failure, Flight>> call(Map<String, dynamic> flightData) async {
    return await repository.createFlight(flightData);
  }
}
