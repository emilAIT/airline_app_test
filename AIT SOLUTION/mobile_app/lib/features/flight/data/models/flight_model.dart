import 'package:ait_airlines/features/flight/domain/entities/flight.dart';
import 'package:ait_airlines/features/airplane/data/models/airplane_model.dart';
import 'package:ait_airlines/features/flight/data/models/airport_model.dart';

class FlightModel extends Flight {
  const FlightModel({
    required super.id,
    required super.flightNumber,
    required super.departureAirport,
    required super.arrivalAirport,
    required super.scheduledDeparture,
    required super.scheduledArrival,
    required super.status,
    required super.airplane,
    required super.basePrice,
    super.availableSeats = 0,
    super.gateDeparture,
    super.gateArrival,
    super.checkInCloses,
  }) : super(airlineCode: 'AIT');

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Parsing flight JSON: $json'); 
    return FlightModel(
      id: json['id'] as int,
      flightNumber: json['flight_number'] as String,
      departureAirport: json['departure_airport'] != null 
          ? AirportModel.fromJson(json['departure_airport'])
          : AirportModel(id: 0, iataCode: '???', name: 'Unknown', city: 'Unknown', country: 'Unknown', timezone: 'UTC'),
      arrivalAirport: json['arrival_airport'] != null
          ? AirportModel.fromJson(json['arrival_airport'])
          : AirportModel(id: 0, iataCode: '???', name: 'Unknown', city: 'Unknown', country: 'Unknown', timezone: 'UTC'),
      scheduledDeparture: DateTime.parse(json['scheduled_departure']),
      scheduledArrival: DateTime.parse(json['scheduled_arrival']),
      status: json['status'] as String,
      airplane: json['airplane'] != null
          ? AirplaneModel.fromJson(json['airplane'])
          : AirplaneModel(id: 0, model: 'Unknown', registration: 'N/A', manufacturer: 'Unknown', totalSeats: 0, economySeats: 0),
      basePrice: (json['base_price'] as num).toDouble(),
      availableSeats: json['available_seats'] as int? ?? 0,
      gateDeparture: json['gate_departure'] as String?,
      gateArrival: json['gate_arrival'] as String?,
      checkInCloses: json['check_in_closes'] != null 
          ? DateTime.parse(json['check_in_closes'])
          : null,
    );
  }
}
