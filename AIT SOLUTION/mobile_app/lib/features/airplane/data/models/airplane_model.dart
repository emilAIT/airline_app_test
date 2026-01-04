import 'package:ait_airlines/features/airplane/domain/entities/airplane.dart';

class AirplaneModel extends Airplane {
  const AirplaneModel({
    required super.id,
    required super.model,
    required super.registration,
    required super.manufacturer,
    required super.totalSeats,
    required super.economySeats,
    super.businessSeats,
  });

  factory AirplaneModel.fromJson(Map<String, dynamic> json) {
    return AirplaneModel(
      id: json['id'] as int,
      model: json['model']?.toString() ?? '',
      registration: json['registration']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      totalSeats: json['total_seats'] as int? ?? 0,
      economySeats: json['economy_seats'] as int? ?? 0,
      businessSeats: json['business_seats'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'registration': registration,
      'manufacturer': manufacturer,
      'total_seats': totalSeats,
      'economy_seats': economySeats,
      'business_seats': businessSeats,
    };
  }
}
