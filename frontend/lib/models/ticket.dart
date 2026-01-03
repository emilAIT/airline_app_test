class Ticket {
  final int? id;
  final String pnr;
  final String passengerName;
  final String? flightNumber;
  final String seat;
  final String? gate;
  final String? boardingTime;
  final String? qrData;
  final String? ticketNumber;
  final String? passportNumber;
  final String? nationality;

  Ticket({
    this.id,
    required this.pnr,
    required this.passengerName,
    this.flightNumber,
    required this.seat,
    this.gate,
    this.boardingTime,
    this.qrData,
    this.ticketNumber,
    this.passportNumber,
    this.nationality,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      passengerName: json['passenger_name'] ?? '',
      flightNumber: json['flight_number'],
      seat: json['seat_number'] ?? json['seat'] ?? '',
      gate: json['gate'],
      boardingTime: json['boarding_time'],
      qrData: json['qr_data'],
      pnr: (json['pnr'] ?? '').toString(),
      ticketNumber: json['ticket_number'],
      passportNumber: json['passport_number'],
      nationality: json['nationality'],
    );
  }
}