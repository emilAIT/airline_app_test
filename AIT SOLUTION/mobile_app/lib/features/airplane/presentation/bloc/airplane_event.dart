import 'package:equatable/equatable.dart';
import 'package:ait_airlines/features/airplane/domain/entities/airplane.dart';

abstract class AirplaneEvent extends Equatable {
  const AirplaneEvent();

  @override
  List<Object> get props => [];
}

class FetchAirplanes extends AirplaneEvent {}

class AddAirplane extends AirplaneEvent {
  final Airplane airplane;

  const AddAirplane(this.airplane);

  @override
  List<Object> get props => [airplane];
}

class DeleteAirplane extends AirplaneEvent {
  final int id;

  const DeleteAirplane(this.id);

  @override
  List<Object> get props => [id];
}
