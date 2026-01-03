import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';

@injectable
class UpdateFlightStatusUseCase {
  final FlightRepository repository;

  UpdateFlightStatusUseCase(this.repository);

  Future<Either<Failure, Flight>> call(int flightId, String status) async {
    return await repository.updateFlightStatus(flightId, status);
  }
}
