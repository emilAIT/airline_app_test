import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/airplane.dart';

abstract class AirplaneRepository {
  Future<Either<Failure, List<Airplane>>> getAirplanes();
  Future<Either<Failure, Airplane>> addAirplane(Airplane airplane);
  Future<Either<Failure, Unit>> deleteAirplane(int id);
}
