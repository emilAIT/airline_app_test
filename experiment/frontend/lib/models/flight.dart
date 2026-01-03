import 'aviation.dart';

class Flight {
  final int id;
  final String flightNumber;
  final String departureAirportCode;
  final String arrivalAirportCode;
  final int airplaneId;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String status;
  final double basePrice;
  final String? gate;
  final String? terminal;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.departureAirportCode,
    required this.arrivalAirportCode,
    required this.airplaneId,
    required this.departureTime,
    required this.arrivalTime,
    required this.status,
    required this.basePrice,
    this.gate,
    this.terminal,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    // Parse times as UTC (backend sends UTC times) and convert to local time for display
    DateTime parseUtcTime(String timeStr) {
      DateTime utcTime;
      // Ensure we parse as UTC - backend sends UTC times
      if (timeStr.endsWith('Z') || timeStr.contains('+') || (timeStr.contains('-') && timeStr.length > 19)) {
        // Has timezone indicator, parse directly
        utcTime = DateTime.parse(timeStr).toUtc();
      } else {
        // No timezone indicator, assume UTC and append 'Z'
        utcTime = DateTime.parse('${timeStr}Z').toUtc();
      }
      // Convert UTC to local time for display (Kyrgyzstan is UTC+6)
      return utcTime.toLocal();
    }
    
    return Flight(
      id: json['id'],
      flightNumber: json['flight_number'],
      departureAirportCode: json['departure_airport_code'],
      arrivalAirportCode: json['arrival_airport_code'],
      airplaneId: json['airplane_id'],
      departureTime: parseUtcTime(json['departure_time']),
      arrivalTime: parseUtcTime(json['arrival_time']),
      status: json['status'],
      basePrice: (json['base_price'] as num).toDouble(),
      gate: json['gate'],
      terminal: json['terminal'],
    );
  }

  Duration get duration => arrivalTime.difference(departureTime);
  bool get isCancelled => status == 'CANCELLED';
  bool get isDeparted => status == 'DEPARTED';
}

class SeatStatus {
  final int id;
  final int airplaneId;
  final String seatNumber;
  final String category;
  final bool isOccupied;
  final bool isHeld;

  SeatStatus({
    required this.id,
    required this.airplaneId,
    required this.seatNumber,
    required this.category,
    required this.isOccupied,
    required this.isHeld,
  });

  factory SeatStatus.fromJson(Map<String, dynamic> json) {
    return SeatStatus(
      id: json['id'],
      airplaneId: json['airplane_id'],
      seatNumber: json['seat_number'],
      category: json['category'],
      isOccupied: json['is_occupied'] ?? false,
      isHeld: json['is_held'] ?? false,
    );
  }

  bool get isAvailable => !isOccupied && !isHeld;
}

class Announcement {
  final int id;
  final int flightId;
  final int? userId;  // NULL = public, not NULL = personal
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.flightId,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Parse UTC time from backend and convert to local time for display (Kyrgyzstan UTC+6)
    DateTime createdAt;
    if (json['created_at'] is String) {
      final dateStr = json['created_at'] as String;
      DateTime utcTime;
      if (dateStr.endsWith('Z') || dateStr.contains('+') || dateStr.contains('-', 10)) {
        utcTime = DateTime.parse(dateStr).toUtc();
      } else {
        utcTime = DateTime.parse('${dateStr}Z').toUtc();
      }
      // Convert UTC to local time for display
      createdAt = utcTime.toLocal();
    } else {
      final utcTime = DateTime.parse(json['created_at'].toString()).toUtc();
      createdAt = utcTime.toLocal();
    }
    
    return Announcement(
      id: json['id'],
      flightId: json['flight_id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      createdAt: createdAt,
    );
  }
}


