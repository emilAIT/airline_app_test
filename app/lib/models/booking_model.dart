import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingPublic {
  final String id;
  final String pnr;
  final BookingStatus status;
  @JsonKey(name: 'flight_id')
  final String flightId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  BookingPublic({
    required this.id,
    required this.pnr,
    required this.status,
    required this.flightId,
    required this.createdAt,
  });

  factory BookingPublic.fromJson(Map<String, dynamic> json) =>
      _$BookingPublicFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPublicToJson(this);
}

@JsonSerializable()
class BookingsPublic {
  final List<BookingPublic> data;
  final int count;

  BookingsPublic({
    required this.data,
    required this.count,
  });

  factory BookingsPublic.fromJson(Map<String, dynamic> json) =>
      _$BookingsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$BookingsPublicToJson(this);
}

@JsonSerializable()
class BookingCreate {
  @JsonKey(name: 'flight_id')
  final String flightId;
  final List<BookingPassenger> passengers;

  BookingCreate({
    required this.flightId,
    required this.passengers,
  });

  factory BookingCreate.fromJson(Map<String, dynamic> json) =>
      _$BookingCreateFromJson(json);

  Map<String, dynamic> toJson() => _$BookingCreateToJson(this);
}

@JsonSerializable()
class BookingPassenger {
  @JsonKey(name: 'passenger_name')
  final String passengerName;
  @JsonKey(name: 'seat_id')
  final String? seatId;

  BookingPassenger({
    required this.passengerName,
    this.seatId,
  });

  factory BookingPassenger.fromJson(Map<String, dynamic> json) =>
      _$BookingPassengerFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPassengerToJson(this);
}

enum BookingStatus {
  @JsonValue('CREATED')
  created,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
}

