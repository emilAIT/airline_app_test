import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/airplane.dart';
import '../repositories/airplane_repository.dart';

@injectable
class AddAirplaneUseCase implements UseCase<Airplane, AddAirplaneParams> {
  final AirplaneRepository repository;

  AddAirplaneUseCase(this.repository);

  @override
  Future<Either<Failure, Airplane>> call(AddAirplaneParams params) async {
    return await repository.addAirplane(params.airplane);
  }
}

class AddAirplaneParams extends Equatable {
  final Airplane airplane;

  const AddAirplaneParams(this.airplane);

  @override
  List<Object> get props => [airplane];
}
