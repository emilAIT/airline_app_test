import 'package:equatable/equatable.dart';

class Airplane extends Equatable {
  final int id;
  final String model;
  final String registration;
  final String manufacturer;
  final int totalSeats;
  final int economySeats;
  final int businessSeats;

  const Airplane({
    required this.id,
    required this.model,
    required this.registration,
    required this.manufacturer,
    required this.totalSeats,
    required this.economySeats,
    this.businessSeats = 0,
  });

  @override
  List<Object?> get props => [
    id, model, registration, manufacturer, 
    totalSeats, economySeats, businessSeats
  ];
}
