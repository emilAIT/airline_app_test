import 'package:equatable/equatable.dart';

class Airport extends Equatable {
  final int id;
  final String code;
  final String name;
  final String city;
  final String country;

  const Airport({
    required this.id,
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  @override
  List<Object?> get props => [id, code, name, city, country];
}

class Airplane extends Equatable {
  final int id;
  final String model;
  final String registrationNumber;
  final Map<String, dynamic> seatTemplate;
  final int totalSeats;

  const Airplane({
    required this.id,
    required this.model,
    required this.registrationNumber,
    required this.seatTemplate,
    required this.totalSeats,
  });

  @override
  List<Object?> get props => [id, model, registrationNumber, seatTemplate, totalSeats];
}
