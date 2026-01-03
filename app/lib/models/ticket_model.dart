import 'package:json_annotation/json_annotation.dart';

part 'ticket_model.g.dart';

@JsonSerializable()
class TicketPublic {
  final String id;
  @JsonKey(name: 'ticket_number')
  final String ticketNumber;
  @JsonKey(name: 'booking_id')
  final String bookingId;
  @JsonKey(name: 'flight_seat_id')
  final String? flightSeatId;
  @JsonKey(name: 'passenger_name')
  final String passengerName;
  @JsonKey(name: 'seat_number')
  final String seatNumber;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  TicketPublic({
    required this.id,
    required this.ticketNumber,
    required this.bookingId,
    this.flightSeatId,
    required this.passengerName,
    required this.seatNumber,
    required this.createdAt,
  });

  factory TicketPublic.fromJson(Map<String, dynamic> json) =>
      _$TicketPublicFromJson(json);

  Map<String, dynamic> toJson() => _$TicketPublicToJson(this);
}

@JsonSerializable()
class TicketsPublic {
  final List<TicketPublic> data;
  final int count;

  TicketsPublic({
    required this.data,
    required this.count,
  });

  factory TicketsPublic.fromJson(Map<String, dynamic> json) =>
      _$TicketsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$TicketsPublicToJson(this);
}
