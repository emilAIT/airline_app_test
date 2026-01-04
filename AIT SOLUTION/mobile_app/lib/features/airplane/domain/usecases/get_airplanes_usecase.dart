import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/airplane.dart';
import '../repositories/airplane_repository.dart';

@injectable
class GetAirplanesUseCase implements UseCase<List<Airplane>, NoParams> {
  final AirplaneRepository repository;

  GetAirplanesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Airplane>>> call(NoParams params) async {
    return await repository.getAirplanes();
  }
}
