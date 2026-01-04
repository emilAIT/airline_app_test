import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:ait_airlines/core/error/failures.dart';
import 'package:ait_airlines/core/usecases/usecase.dart';
import 'package:ait_airlines/features/airplane/domain/repositories/airplane_repository.dart';

@injectable
class DeleteAirplaneUseCase implements UseCase<Unit, int> {
  final AirplaneRepository repository;

  DeleteAirplaneUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int id) async {
    return await repository.deleteAirplane(id);
  }
}
