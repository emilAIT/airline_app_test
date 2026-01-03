import 'package:equatable/equatable.dart';

class Airport extends Equatable {
  final int id;
  final String iataCode;
  final String name;
  final String city;
  final String country;
  final String timezone;

  const Airport({
    required this.id,
    required this.iataCode,
    required this.name,
    required this.city,
    required this.country,
    required this.timezone,
  });

  @override
  List<Object?> get props => [id, iataCode, name, city, country, timezone];
}
