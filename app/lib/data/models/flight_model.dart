import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_assets.dart';

class AirportModel extends Airport {
  const AirportModel({
    required super.id,
    required super.code,
    required super.name,
    required super.city,
    required super.country,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class AirplaneModel extends Airplane {
  const AirplaneModel({
    required super.id,
    required super.model,
    required super.registrationNumber,
    required super.seatTemplate,
    required super.totalSeats,
  });

  factory AirplaneModel.fromJson(Map<String, dynamic> json) {
    return AirplaneModel(
      id: json['id'] ?? 0, // Search results may not include id
      model: json['model'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      seatTemplate: json['seat_template'] ?? {},
      totalSeats: json['total_seats'] ?? 0,
    );
  }
}

class FlightModel extends Flight {
  const FlightModel({
    required super.id,
    required super.flightNumber,
    required super.origin,
    required super.destination,
    required super.airplane,
    required super.scheduledDeparture,
    required super.scheduledArrival,
    super.gate,
    super.terminal,
    required super.status,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    // Handle both full flight details and search results formats
    final originData = json['origin_airport'] ?? json['origin'];
    final destinationData = json['destination_airport'] ?? json['destination'];
    final airplaneData = json['airplane'];

    return FlightModel(
      id: json['id'] ?? 0,
      flightNumber: json['flight_number'] ?? '',
      origin: AirportModel.fromJson(originData ?? {}),
      destination: AirportModel.fromJson(destinationData ?? {}),
      airplane: AirplaneModel.fromJson(airplaneData ?? {}),
      scheduledDeparture: DateTime.parse(json['scheduled_departure'] ??
          json['departure_time'] ??
          DateTime.now().toIso8601String()),
      scheduledArrival: DateTime.parse(json['scheduled_arrival'] ??
          json['arrival_time'] ??
          DateTime.now().toIso8601String()),
      gate: json['gate'],
      terminal: json['terminal'],
      status: FlightStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] ?? 'SCHEDULED'),
        orElse: () => FlightStatus.scheduled,
      ),
    );
  }
}
