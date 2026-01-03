enum SeatCategory { standard, extraLegroom }
enum SeatStatus { available, occupied, held }

class Seat {
  final String seatNumber;
  final SeatCategory category;
  SeatStatus status;

  Seat({
    required this.seatNumber,
    required this.category,
    required this.status,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatNumber: (json['seat_number'] ?? json['label'] ?? '').toString(),
      category: json['category'] == 'EXTRA'
          ? SeatCategory.extraLegroom
          : SeatCategory.standard,
      status: _parseStatus(json['status']),
    );
  }

  static SeatStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'OCCUPIED':
      case 'BOOKED':
        return SeatStatus.occupied;
      case 'HELD':
        return SeatStatus.held;
      default:
        return SeatStatus.available;
    }
  }

  bool get isSelectable => status == SeatStatus.available;
}