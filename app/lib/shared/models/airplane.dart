import 'seat_template.dart';

class Airplane {
  final int id;
  final String model;
  final String registration;
  final int totalSeats;
  final List<SeatTemplate>? seatTemplate;

  Airplane({
    required this.id,
    required this.model,
    required this.registration,
    required this.totalSeats,
    this.seatTemplate,
  });

  factory Airplane.fromJson(Map<String, dynamic> json) {
    return Airplane(
      id: (json['id'] as num).toInt(),
      model: json['model'] as String,
      registration: json['registration'] as String,
      totalSeats: (json['total_seats'] as num).toInt(),
      seatTemplate: json['seat_template'] != null
          ? (json['seat_template'] as List)
              .map((e) => SeatTemplate.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'registration': registration,
      'total_seats': totalSeats,
      if (seatTemplate != null)
        'seat_template': seatTemplate!.map((e) => e.toJson()).toList(),
    };
  }
}

