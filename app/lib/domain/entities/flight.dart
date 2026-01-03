import 'package:equatable/equatable.dart';
import 'flight_assets.dart';

enum FlightStatus {
  scheduled,
  delayed,
  boarding,
  departed,
  landed,
  cancelled,
}

class Flight extends Equatable {
  final int id;
  final String flightNumber;
  final Airport origin;
  final Airport destination;
  final Airplane airplane;
  final DateTime scheduledDeparture;
  final DateTime scheduledArrival;
  final String? gate;
  final String? terminal;
  final FlightStatus status;

  const Flight({
    required this.id,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.airplane,
    required this.scheduledDeparture,
    required this.scheduledArrival,
    this.gate,
    this.terminal,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        flightNumber,
        origin,
        destination,
        airplane,
        scheduledDeparture,
        scheduledArrival,
        gate,
        terminal,
        status,
      ];
}
