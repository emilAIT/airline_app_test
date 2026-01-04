import 'package:equatable/equatable.dart';
import 'package:ait_airlines/features/airplane/domain/entities/airplane.dart';
import 'package:ait_airlines/features/flight/domain/entities/airport.dart';

class Flight extends Equatable {
  final int id;
  final String flightNumber;
  final Airport departureAirport;
  final Airport arrivalAirport;
  final DateTime scheduledDeparture;
  final DateTime scheduledArrival;
  final String status;
  final Airplane airplane;
  final double basePrice;
  final int availableSeats;
  final String airlineCode;
  final String? gateDeparture;
  final String? gateArrival;
  final DateTime? checkInCloses;

  const Flight({
    required this.id,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.scheduledDeparture,
    required this.scheduledArrival,
    required this.status,
    required this.airplane,
    required this.basePrice,
    this.availableSeats = 0,
    required this.airlineCode,
    this.gateDeparture,
    this.gateArrival,
    this.checkInCloses,
  });

  @override
  List<Object?> get props => [
        id,
        flightNumber,
        departureAirport,
        arrivalAirport,
        scheduledDeparture,
        scheduledArrival,
        status,
        airplane,
        basePrice,
        availableSeats,
        airlineCode,
        gateDeparture,
        gateArrival,
        checkInCloses,
      ];
}
