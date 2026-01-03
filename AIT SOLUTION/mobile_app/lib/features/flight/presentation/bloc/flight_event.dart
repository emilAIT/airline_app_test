import 'package:equatable/equatable.dart';

abstract class FlightEvent extends Equatable {
  const FlightEvent();
  @override
  List<Object?> get props => [];
}

class FetchFlights extends FlightEvent {
  final String? departure;
  final String? arrival;
  final String? date;
  final int? passengersCount;
  const FetchFlights(
      {this.departure, this.arrival, this.date, this.passengersCount});
}

class FetchAirports extends FlightEvent {}

class CreateAirportRequested extends FlightEvent {
  final Map<String, dynamic> airportData;
  const CreateAirportRequested(this.airportData);
}

class CreateFlightRequested extends FlightEvent {
  final Map<String, dynamic> flightData;
  const CreateFlightRequested(this.flightData);
}

class UpdateFlightStatusRequested extends FlightEvent {
  final int flightId;
  final String status;
  const UpdateFlightStatusRequested(
      {required this.flightId, required this.status});
}

class UpdateFlightGatesRequested extends FlightEvent {
  final int flightId;
  final String gateDeparture;
  final String gateArrival;
  const UpdateFlightGatesRequested(
      this.flightId, this.gateDeparture, this.gateArrival);
}

class FlightSeatMapRequested extends FlightEvent {
  final int flightId;
  const FlightSeatMapRequested(this.flightId);
}
