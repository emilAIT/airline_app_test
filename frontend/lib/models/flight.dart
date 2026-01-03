class Flight {
  final int id;
  final String flightNumber;
  final String originCode;
  final String destinationCode;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String status;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.originCode,
    required this.destinationCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.status,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'],
      flightNumber: json['flight_number'],
      originCode: json['origin_code'],
      destinationCode: json['destination_code'],
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: DateTime.parse(json['arrival_time']),
      price: (json['price'] as num).toDouble(),
      status: json['status'],
    );
  }
}
