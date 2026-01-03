class Airport {
  final String code;
  final String name;
  final String city;
  final String country;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      code: json['code'],
      name: json['name'],
      city: json['city'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'city': city,
      'country': country,
    };
  }
}

class Airplane {
  final int id;
  final String name;
  final String model;
  final List<Seat> seats;

  Airplane({
    required this.id,
    required this.name,
    required this.model,
    this.seats = const [],
  });

  factory Airplane.fromJson(Map<String, dynamic> json) {
    return Airplane(
      id: json['id'],
      name: json['name'],
      model: json['model'],
      seats: (json['seats'] as List<dynamic>?)
              ?.map((s) => Seat.fromJson(s))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'seats': seats.map((s) => s.toJson()).toList(),
    };
  }
}

class Seat {
  final int id;
  final int airplaneId;
  final String seatNumber;
  final String category;

  Seat({
    required this.id,
    required this.airplaneId,
    required this.seatNumber,
    required this.category,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      airplaneId: json['airplane_id'],
      seatNumber: json['seat_number'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airplane_id': airplaneId,
      'seat_number': seatNumber,
      'category': category,
    };
  }
}


