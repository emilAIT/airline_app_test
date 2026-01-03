import 'package:equatable/equatable.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/airport.dart';
import '../../domain/entities/seat_map.dart';

abstract class FlightState extends Equatable {
  const FlightState();
  @override
  List<Object?> get props => [];
}

class FlightInitial extends FlightState {}

class FlightLoading extends FlightState {}

class FlightsLoaded extends FlightState {
  final List<Flight> flights;
  const FlightsLoaded(this.flights);
  @override
  List<Object?> get props => [flights];
}

class AirportsLoaded extends FlightState {
  final List<Airport> airports;
  const AirportsLoaded(this.airports);
  @override
  List<Object?> get props => [airports];
}

class AirportCreated extends FlightState {
  final Airport airport;
  const AirportCreated(this.airport);
  @override
  List<Object?> get props => [airport];
}

class FlightCreated extends FlightState {
  final Flight flight;
  const FlightCreated(this.flight);
  @override
  List<Object?> get props => [flight];
}

class FlightUpdated extends FlightState {
  final Flight flight;
  const FlightUpdated(this.flight);
  @override
  List<Object?> get props => [flight];
}

class FlightSeatMapSuccess extends FlightState {
  final SeatMap seatMap;
  const FlightSeatMapSuccess(this.seatMap);
  @override
  List<Object?> get props => [seatMap];
}

class FlightError extends FlightState {
  final String message;
  const FlightError(this.message);
  @override
  List<Object?> get props => [message];
}
