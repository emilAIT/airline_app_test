import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';

class GetFlightsParams {
  final String? departure;
  final String? arrival;
  GetFlightsParams({this.departure, this.arrival});
}

@injectable
class GetFlightsUseCase {
  final FlightRepository repository;

  GetFlightsUseCase(this.repository);

  Future<Either<Failure, List<Flight>>> call([GetFlightsParams? params]) async {
    return await repository.getFlights(
      departure: params?.departure,
      arrival: params?.arrival,
    );
  }
}
