import 'package:ait_airlines/features/flight/domain/entities/airport.dart';

class AirportModel extends Airport {
  const AirportModel({
    required super.id,
    required super.iataCode,
    required super.name,
    required super.city,
    required super.country,
    required super.timezone,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      id: json['id'] as int,
      iataCode: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      timezone: json['timezone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': iataCode,
      'name': name,
      'city': city,
      'country': country,
      'timezone': timezone,
    };
  }
}
