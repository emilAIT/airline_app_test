import 'flight.dart';

class Booking {
  final int id;
  final String pnr;
  final int flightId;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final List<Ticket> tickets;
  final Flight? flight;

  Booking({
    required this.id,
    required this.pnr,
    required this.flightId,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.tickets,
    this.flight,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse createdAt as UTC time (backend sends UTC)
    DateTime createdAt;
    if (json['created_at'] is String) {
      final dateStr = json['created_at'] as String;
      // If it ends with Z or has timezone, parse directly
      if (dateStr.endsWith('Z') || dateStr.contains('+') || dateStr.contains('-', 10)) {
        createdAt = DateTime.parse(dateStr).toUtc();
      } else {
        // If no timezone, assume UTC and parse as UTC
        createdAt = DateTime.parse('${dateStr}Z').toUtc();
      }
    } else {
      createdAt = DateTime.parse(json['created_at'].toString()).toUtc();
    }
    
    return Booking(
      id: json['id'],
      pnr: json['pnr'],
      flightId: json['flight_id'],
      status: json['status'],
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: createdAt,
      tickets: (json['tickets'] as List<dynamic>?)
              ?.map((t) => Ticket.fromJson(t))
              .toList() ??
          [],
      flight: json['flight'] != null ? Flight.fromJson(json['flight']) : null,
    );
  }

  bool get isConfirmed => status == 'CONFIRMED';
  bool get isPending => status == 'PENDING';
  bool get isCancelled => status == 'CANCELLED';
}

class Ticket {
  final int id;
  final int bookingId;
  final String passengerName;
  final String seatNumber;
  final String ticketNumber;

  Ticket({
    required this.id,
    required this.bookingId,
    required this.passengerName,
    required this.seatNumber,
    required this.ticketNumber,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      bookingId: json['booking_id'],
      passengerName: json['passenger_name'],
      seatNumber: json['seat_number'],
      ticketNumber: json['ticket_number'],
    );
  }
}

class BookingCreate {
  final int flightId;
  final List<PassengerInfo> passengers;

  BookingCreate({
    required this.flightId,
    required this.passengers,
  });

  Map<String, dynamic> toJson() {
    return {
      'flight_id': flightId,
      'passengers': passengers.map((p) => p.toJson()).toList(),
    };
  }
}

class PassengerInfo {
  final String passengerName;
  final String passportNumber;
  final String? seatNumber;

  PassengerInfo({
    required this.passengerName,
    required this.passportNumber,
    this.seatNumber,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'passenger_name': passengerName,
      'passport_number': passportNumber,
    };
    if (seatNumber != null && seatNumber!.isNotEmpty) {
      json['seat_number'] = seatNumber!;
    }
    return json;
  }
}

class BoardingPass {
  final String passenger;
  final String seat;
  final String flight;
  final String gate;
  final DateTime boardingTime;
  final String qrCode;

  BoardingPass({
    required this.passenger,
    required this.seat,
    required this.flight,
    required this.gate,
    required this.boardingTime,
    required this.qrCode,
  });

  factory BoardingPass.fromJson(Map<String, dynamic> json) {
    return BoardingPass(
      passenger: json['passenger'],
      seat: json['seat'],
      flight: json['flight'],
      gate: json['gate'],
      boardingTime: DateTime.parse(json['boarding_time']),
      qrCode: json['qr_code'],
    );
  }
}

