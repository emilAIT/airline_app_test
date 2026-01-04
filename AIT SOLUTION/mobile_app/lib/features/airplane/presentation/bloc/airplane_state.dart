import 'package:equatable/equatable.dart';
import 'package:ait_airlines/features/airplane/domain/entities/airplane.dart';

abstract class AirplaneState extends Equatable {
  const AirplaneState();
  
  @override
  List<Object?> get props => [];
}

class AirplaneInitial extends AirplaneState {}

class AirplaneLoading extends AirplaneState {}

class AirplaneLoaded extends AirplaneState {
  final List<Airplane> airplanes;

  const AirplaneLoaded(this.airplanes);

  @override
  List<Object?> get props => [airplanes];
}

class AirplaneError extends AirplaneState {
  final String message;

  const AirplaneError(this.message);

  @override
  List<Object?> get props => [message];
}

class AirplaneOperationSuccess extends AirplaneState {
  final String message;

  const AirplaneOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
