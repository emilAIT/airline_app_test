import 'package:json_annotation/json_annotation.dart';
import 'airplane_model.dart';

part 'seat_model.g.dart';

enum FlightSeatStatus {
  @JsonValue('AVAILABLE')
  available,
  @JsonValue('BOOKED')
  booked,
  @JsonValue('BLOCKED')
  blocked,
}

@JsonSerializable()
class FlightSeat {
  final String id;
  @JsonKey(name: 'flight_id')
  final String flightId;
  final int row;
  @JsonKey(name: 'seat_label')
  final String seatLabel;
  final SeatCategory category;
  final int price;
  final FlightSeatStatus status;

  FlightSeat({
    required this.id,
    required this.flightId,
    required this.row,
    required this.seatLabel,
    required this.category,
    required this.price,
    required this.status,
  });

  factory FlightSeat.fromJson(Map<String, dynamic> json) =>
      _$FlightSeatFromJson(json);

  Map<String, dynamic> toJson() => _$FlightSeatToJson(this);
}

@JsonSerializable()
class SeatMapResponse {
  @JsonKey(name: 'flight_id')
  final String flightId;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  final List<FlightSeat> seats;

  SeatMapResponse({
    required this.flightId,
    required this.flightNumber,
    required this.seats,
  });

  factory SeatMapResponse.fromJson(Map<String, dynamic> json) =>
      _$SeatMapResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SeatMapResponseToJson(this);
}

