class BoardingPass {
  final String passengerName;
  final String flightNumber;
  final String seatNumber;
  final String? gate;
  final DateTime? boardingTime;
  final DateTime departureTime;
  final String qrCode;

  BoardingPass({
    required this.passengerName,
    required this.flightNumber,
    required this.seatNumber,
    this.gate,
    this.boardingTime,
    required this.departureTime,
    required this.qrCode,
  });

  factory BoardingPass.fromJson(Map<String, dynamic> json) {
    return BoardingPass(
      passengerName: json['passenger_name'] as String,
      flightNumber: json['flight_number'] as String,
      seatNumber: json['seat_number'] as String,
      gate: json['gate'] as String?,
      boardingTime: json['boarding_time'] != null
          ? DateTime.parse(json['boarding_time'] as String)
          : null,
      departureTime: DateTime.parse(json['departure_time'] as String),
      qrCode: json['qr_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passenger_name': passengerName,
      'flight_number': flightNumber,
      'seat_number': seatNumber,
      'gate': gate,
      'boarding_time': boardingTime?.toIso8601String(),
      'departure_time': departureTime.toIso8601String(),
      'qr_code': qrCode,
    };
  }
}

