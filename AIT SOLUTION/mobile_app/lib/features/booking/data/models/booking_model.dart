import 'package:ait_airlines/features/booking/domain/entities/booking.dart';
import 'package:ait_airlines/features/flight/data/models/flight_model.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.flightId,
    required super.bookingReference,
    required super.status,
    required super.totalPrice,
    required super.createdAt,
    required super.passengersCount,
    super.flight,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // DEBUG PRINT
    // print("PARSING BookingModel: $json");
    
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BookingModel(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      flightId: parseInt(json['flight_id']),
      bookingReference: json['booking_reference'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'pending',
      totalPrice: parseDouble(json['total_price']),
      passengersCount: parseInt(json['passengers_count']) == 0 ? 1 : parseInt(json['passengers_count']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      flight: json['flight'] != null 
          ? FlightModel.fromJson(json['flight'] as Map<String, dynamic>) 
          : null,
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'flight_id': flightId,
      'booking_reference': bookingReference,
      'status': status,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
