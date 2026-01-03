import 'package:json_annotation/json_annotation.dart';

part 'flight_model.g.dart';

@JsonSerializable()
class FlightPublic {
  final String id;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  @JsonKey(name: 'origin_airport_id')
  final String originAirportId;
  @JsonKey(name: 'destination_airport_id')
  final String destinationAirportId;
  @JsonKey(name: 'origin_airport_code')
  final String? originAirportCode;
  @JsonKey(name: 'destination_airport_code')
  final String? destinationAirportCode;
  @JsonKey(name: 'departure_time')
  final DateTime departureTime;
  @JsonKey(name: 'arrival_time')
  final DateTime arrivalTime;
  final FlightStatus status;
  final String? gate;
  final String? terminal;
  @JsonKey(name: 'airplane_id')
  final String? airplaneId;

  FlightPublic({
    required this.id,
    required this.flightNumber,
    required this.originAirportId,
    required this.destinationAirportId,
    this.originAirportCode,
    this.destinationAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    this.status = FlightStatus.scheduled,
    this.gate,
    this.terminal,
    this.airplaneId,
  });

  factory FlightPublic.fromJson(Map<String, dynamic> json) =>
      _$FlightPublicFromJson(json);

  Map<String, dynamic> toJson() => _$FlightPublicToJson(this);
}

@JsonSerializable()
class FlightSearchResult {
  @JsonKey(name: 'flight_id')
  final String flightId;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  @JsonKey(name: 'origin_airport_code')
  final String originAirportCode;
  @JsonKey(name: 'destination_airport_code')
  final String destinationAirportCode;
  @JsonKey(name: 'departure_time')
  final DateTime departureTime;
  @JsonKey(name: 'arrival_time')
  final DateTime arrivalTime;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'price_from')
  final int priceFrom;
  @JsonKey(name: 'available_seats')
  final int availableSeats;
  final FlightStatus status;

  FlightSearchResult({
    required this.flightId,
    required this.flightNumber,
    required this.originAirportCode,
    required this.destinationAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.priceFrom,
    required this.availableSeats,
    required this.status,
  });

  factory FlightSearchResult.fromJson(Map<String, dynamic> json) =>
      _$FlightSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$FlightSearchResultToJson(this);
}

@JsonSerializable()
class FlightsPublic {
  final List<FlightPublic> data;
  final int count;

  FlightsPublic({
    required this.data,
    required this.count,
  });

  factory FlightsPublic.fromJson(Map<String, dynamic> json) =>
      _$FlightsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$FlightsPublicToJson(this);
}

@JsonSerializable()
class FlightSearchParams {
  final String originAirportId;
  final String destinationAirportId;
  final DateTime departureDateFrom;
  final DateTime? departureDateTo;

  FlightSearchParams({
    required this.originAirportId,
    required this.destinationAirportId,
    required this.departureDateFrom,
    this.departureDateTo,
  });

  factory FlightSearchParams.fromJson(Map<String, dynamic> json) =>
      _$FlightSearchParamsFromJson(json);

  Map<String, dynamic> toJson() => _$FlightSearchParamsToJson(this);
}

enum FlightStatus {
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('BOARDING')
  boarding,
  @JsonValue('DELAYED')
  delayed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('DEPARTED')
  departed,
  @JsonValue('LANDED')
  landed,
}

@JsonSerializable()
class FlightCreate {
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  @JsonKey(name: 'origin_airport_id')
  final String originAirportId;
  @JsonKey(name: 'destination_airport_id')
  final String destinationAirportId;
  @JsonKey(name: 'departure_time')
  final DateTime departureTime;
  @JsonKey(name: 'arrival_time')
  final DateTime arrivalTime;
  final FlightStatus status;
  final String? gate;
  final String? terminal;
  @JsonKey(name: 'airplane_id')
  final String? airplaneId;

  FlightCreate({
    required this.flightNumber,
    required this.originAirportId,
    required this.destinationAirportId,
    required this.departureTime,
    required this.arrivalTime,
    this.status = FlightStatus.scheduled,
    this.gate,
    this.terminal,
    this.airplaneId,
  });

  factory FlightCreate.fromJson(Map<String, dynamic> json) =>
      _$FlightCreateFromJson(json);

  Map<String, dynamic> toJson() => _$FlightCreateToJson(this);
}

@JsonSerializable()
class FlightUpdate {
  @JsonKey(name: 'departure_time')
  final DateTime? departureTime;
  @JsonKey(name: 'arrival_time')
  final DateTime? arrivalTime;
  final FlightStatus? status;
  final String? gate;
  final String? terminal;
  @JsonKey(name: 'airplane_id')
  final String? airplaneId;

  FlightUpdate({
    this.departureTime,
    this.arrivalTime,
    this.status,
    this.gate,
    this.terminal,
    this.airplaneId,
  });

  factory FlightUpdate.fromJson(Map<String, dynamic> json) =>
      _$FlightUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$FlightUpdateToJson(this);
}

@JsonSerializable()
class FlightStatusUpdate {
  final FlightStatus status;

  FlightStatusUpdate({
    required this.status,
  });

  factory FlightStatusUpdate.fromJson(Map<String, dynamic> json) =>
      _$FlightStatusUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$FlightStatusUpdateToJson(this);
}

@JsonSerializable()
class FlightGateTerminalUpdate {
  final String? gate;
  final String? terminal;

  FlightGateTerminalUpdate({
    this.gate,
    this.terminal,
  });

  factory FlightGateTerminalUpdate.fromJson(Map<String, dynamic> json) =>
      _$FlightGateTerminalUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$FlightGateTerminalUpdateToJson(this);
}

