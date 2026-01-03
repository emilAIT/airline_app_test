import 'airport.dart';
import 'airplane.dart';
import 'enums.dart';

class Flight {
  final int id;
  final String flightNumber;
  final int airplaneId;
  final int originAirportId;
  final int destinationAirportId;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double basePrice;
  final String? gate;
  final String? terminal;
  final FlightStatus status;
  final DateTime? boardingTime;
  final Airport? origin;
  final Airport? destination;
  final Airplane? airplane;
  final int? durationMinutes;
  final int? availableSeats;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.airplaneId,
    required this.originAirportId,
    required this.destinationAirportId,
    required this.departureTime,
    required this.arrivalTime,
    required this.basePrice,
    this.gate,
    this.terminal,
    required this.status,
    this.boardingTime,
    this.origin,
    this.destination,
    this.airplane,
    this.durationMinutes,
    this.availableSeats,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      flightNumber: json['flight_number'] as String,
      airplaneId: json['airplane_id'] != null ? (json['airplane_id'] as num).toInt() : 0,
      originAirportId: json['origin_airport_id'] != null ? (json['origin_airport_id'] as num).toInt() : 0,
      destinationAirportId: json['destination_airport_id'] != null ? (json['destination_airport_id'] as num).toInt() : 0,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      basePrice: json['base_price'] != null ? (json['base_price'] as num).toDouble() : 0.0,
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
      status: FlightStatus.fromJson(json['status'] as String),
      boardingTime: json['boarding_time'] != null
          ? DateTime.parse(json['boarding_time'] as String)
          : null,
      origin: json['origin_airport'] != null
          ? Airport.fromJson(json['origin_airport'] as Map<String, dynamic>)
          : null,
      destination: json['destination_airport'] != null
          ? Airport.fromJson(json['destination_airport'] as Map<String, dynamic>)
          : null,
      airplane: json['airplane'] != null
          ? Airplane.fromJson(json['airplane'] as Map<String, dynamic>)
          : null,
      durationMinutes: json['duration_minutes'] != null 
          ? (json['duration_minutes'] as num).toInt() 
          : null,
      availableSeats: json['available_seats'] != null 
          ? (json['available_seats'] as num).toInt() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flight_number': flightNumber,
      'airplane_id': airplaneId,
      'origin_airport_id': originAirportId,
      'destination_airport_id': destinationAirportId,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'base_price': basePrice,
      'gate': gate,
      'terminal': terminal,
      'status': status.toJson(),
      'boarding_time': boardingTime?.toIso8601String(),
      if (origin != null) 'origin': origin!.toJson(),
      if (destination != null) 'destination': destination!.toJson(),
      if (airplane != null) 'airplane': airplane!.toJson(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (availableSeats != null) 'available_seats': availableSeats,
    };
  }
  
  Duration get duration => arrivalTime.difference(departureTime);
}

