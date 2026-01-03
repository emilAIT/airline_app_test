import 'enums.dart';

class Seat {
  final String seatNumber;
  final SeatCategory category;
  final bool isAvailable;
  final double price;

  Seat({
    required this.seatNumber,
    required this.category,
    required this.isAvailable,
    required this.price,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatNumber: json['seat_number'] as String,
      category: SeatCategory.fromJson(json['category'] as String),
      isAvailable: json['is_available'] as bool,
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seat_number': seatNumber,
      'category': category.toJson(),
      'is_available': isAvailable,
      'price': price,
    };
  }
}

class SeatMap {
  final int flightId;
  final List<Seat> seats;

  SeatMap({
    required this.flightId,
    required this.seats,
  });

  factory SeatMap.fromJson(Map<String, dynamic> json) {
    return SeatMap(
      flightId: (json['flight_id'] as num).toInt(),
      seats: (json['seats'] as List)
          .map((e) => Seat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flight_id': flightId,
      'seats': seats.map((e) => e.toJson()).toList(),
    };
  }
}

