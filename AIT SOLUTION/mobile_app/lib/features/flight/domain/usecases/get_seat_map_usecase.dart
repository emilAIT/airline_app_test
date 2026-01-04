import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/features/flight/domain/repositories/flight_repository.dart';

@injectable
class GetSeatMapUseCase {
  final FlightRepository repository;

  GetSeatMapUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(int flightId) async {
    return await repository.getSeatMap(flightId);
  }
}
