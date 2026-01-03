import 'package:json_annotation/json_annotation.dart';

part 'airplane_model.g.dart';

@JsonSerializable()
class AirplanePublic {
  final String id;
  final String model;
  @JsonKey(name: 'total_seats')
  final int totalSeats;

  AirplanePublic({
    required this.id,
    required this.model,
    required this.totalSeats,
  });

  factory AirplanePublic.fromJson(Map<String, dynamic> json) =>
      _$AirplanePublicFromJson(json);

  Map<String, dynamic> toJson() => _$AirplanePublicToJson(this);
}

@JsonSerializable()
class SeatTemplateBase {
  final int row;
  @JsonKey(name: 'seat_label')
  final String seatLabel;
  final SeatCategory category;

  SeatTemplateBase({
    required this.row,
    required this.seatLabel,
    this.category = SeatCategory.standard,
  });

  factory SeatTemplateBase.fromJson(Map<String, dynamic> json) =>
      _$SeatTemplateBaseFromJson(json);

  Map<String, dynamic> toJson() => _$SeatTemplateBaseToJson(this);
}

@JsonSerializable()
class AirplaneCreateRequest {
  final String model;
  @JsonKey(name: 'seat_map')
  final List<SeatTemplateBase> seatMap;

  AirplaneCreateRequest({
    required this.model,
    required this.seatMap,
  });

  factory AirplaneCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$AirplaneCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AirplaneCreateRequestToJson(this);
}

@JsonSerializable()
class AirplaneUpdate {
  final String? model;

  AirplaneUpdate({
    this.model,
  });

  factory AirplaneUpdate.fromJson(Map<String, dynamic> json) =>
      _$AirplaneUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AirplaneUpdateToJson(this);
}

enum SeatCategory {
  @JsonValue('STANDARD')
  standard,
  @JsonValue('EXTRA_LEGROOM')
  extraLegroom,
}

@JsonSerializable()
class AirplaneSeatMapResponse {
  @JsonKey(name: 'airplane_id')
  final String airplaneId;
  final String model;
  @JsonKey(name: 'total_seats')
  final int totalSeats;
  @JsonKey(name: 'seat_map')
  final List<SeatTemplateBase> seatMap;

  AirplaneSeatMapResponse({
    required this.airplaneId,
    required this.model,
    required this.totalSeats,
    required this.seatMap,
  });

  factory AirplaneSeatMapResponse.fromJson(Map<String, dynamic> json) =>
      _$AirplaneSeatMapResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AirplaneSeatMapResponseToJson(this);
}

