import 'package:json_annotation/json_annotation.dart';

part 'seat_hold_model.g.dart';

@JsonSerializable()
class SeatHoldPublic {
  final String id;
  final String flightId;
  final String flightSeatId;
  final DateTime expiresAt;

  SeatHoldPublic({
    required this.id,
    required this.flightId,
    required this.flightSeatId,
    required this.expiresAt,
  });

  factory SeatHoldPublic.fromJson(Map<String, dynamic> json) =>
      _$SeatHoldPublicFromJson(json);

  Map<String, dynamic> toJson() => _$SeatHoldPublicToJson(this);
}

@JsonSerializable()
class SeatHoldsPublic {
  final List<SeatHoldPublic> data;
  final int count;

  SeatHoldsPublic({
    required this.data,
    required this.count,
  });

  factory SeatHoldsPublic.fromJson(Map<String, dynamic> json) =>
      _$SeatHoldsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$SeatHoldsPublicToJson(this);
}

@JsonSerializable()
class SeatHoldCreate {
  final String flightId;
  final String flightSeatId;

  SeatHoldCreate({
    required this.flightId,
    required this.flightSeatId,
  });

  factory SeatHoldCreate.fromJson(Map<String, dynamic> json) =>
      _$SeatHoldCreateFromJson(json);

  Map<String, dynamic> toJson() => _$SeatHoldCreateToJson(this);
}

