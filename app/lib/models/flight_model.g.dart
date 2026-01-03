// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlightPublic _$FlightPublicFromJson(Map<String, dynamic> json) => FlightPublic(
      id: json['id'] as String,
      flightNumber: json['flight_number'] as String,
      originAirportId: json['origin_airport_id'] as String,
      destinationAirportId: json['destination_airport_id'] as String,
      originAirportCode: json['origin_airport_code'] as String?,
      destinationAirportCode: json['destination_airport_code'] as String?,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      status: $enumDecodeNullable(_$FlightStatusEnumMap, json['status']) ??
          FlightStatus.scheduled,
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
      airplaneId: json['airplane_id'] as String?,
    );

Map<String, dynamic> _$FlightPublicToJson(FlightPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'flight_number': instance.flightNumber,
      'origin_airport_id': instance.originAirportId,
      'destination_airport_id': instance.destinationAirportId,
      'origin_airport_code': instance.originAirportCode,
      'destination_airport_code': instance.destinationAirportCode,
      'departure_time': instance.departureTime.toIso8601String(),
      'arrival_time': instance.arrivalTime.toIso8601String(),
      'status': _$FlightStatusEnumMap[instance.status]!,
      'gate': instance.gate,
      'terminal': instance.terminal,
      'airplane_id': instance.airplaneId,
    };

const _$FlightStatusEnumMap = {
  FlightStatus.scheduled: 'SCHEDULED',
  FlightStatus.boarding: 'BOARDING',
  FlightStatus.delayed: 'DELAYED',
  FlightStatus.cancelled: 'CANCELLED',
  FlightStatus.departed: 'DEPARTED',
  FlightStatus.landed: 'LANDED',
};

FlightSearchResult _$FlightSearchResultFromJson(Map<String, dynamic> json) =>
    FlightSearchResult(
      flightId: json['flight_id'] as String,
      flightNumber: json['flight_number'] as String,
      originAirportCode: json['origin_airport_code'] as String,
      destinationAirportCode: json['destination_airport_code'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      priceFrom: (json['price_from'] as num).toInt(),
      availableSeats: (json['available_seats'] as num).toInt(),
      status: $enumDecode(_$FlightStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$FlightSearchResultToJson(FlightSearchResult instance) =>
    <String, dynamic>{
      'flight_id': instance.flightId,
      'flight_number': instance.flightNumber,
      'origin_airport_code': instance.originAirportCode,
      'destination_airport_code': instance.destinationAirportCode,
      'departure_time': instance.departureTime.toIso8601String(),
      'arrival_time': instance.arrivalTime.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'price_from': instance.priceFrom,
      'available_seats': instance.availableSeats,
      'status': _$FlightStatusEnumMap[instance.status]!,
    };

FlightsPublic _$FlightsPublicFromJson(Map<String, dynamic> json) =>
    FlightsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => FlightPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$FlightsPublicToJson(FlightsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

FlightSearchParams _$FlightSearchParamsFromJson(Map<String, dynamic> json) =>
    FlightSearchParams(
      originAirportId: json['originAirportId'] as String,
      destinationAirportId: json['destinationAirportId'] as String,
      departureDateFrom: DateTime.parse(json['departureDateFrom'] as String),
      departureDateTo: json['departureDateTo'] == null
          ? null
          : DateTime.parse(json['departureDateTo'] as String),
    );

Map<String, dynamic> _$FlightSearchParamsToJson(FlightSearchParams instance) =>
    <String, dynamic>{
      'originAirportId': instance.originAirportId,
      'destinationAirportId': instance.destinationAirportId,
      'departureDateFrom': instance.departureDateFrom.toIso8601String(),
      'departureDateTo': instance.departureDateTo?.toIso8601String(),
    };

FlightCreate _$FlightCreateFromJson(Map<String, dynamic> json) => FlightCreate(
      flightNumber: json['flight_number'] as String,
      originAirportId: json['origin_airport_id'] as String,
      destinationAirportId: json['destination_airport_id'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      status: $enumDecodeNullable(_$FlightStatusEnumMap, json['status']) ??
          FlightStatus.scheduled,
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
      airplaneId: json['airplane_id'] as String?,
    );

Map<String, dynamic> _$FlightCreateToJson(FlightCreate instance) =>
    <String, dynamic>{
      'flight_number': instance.flightNumber,
      'origin_airport_id': instance.originAirportId,
      'destination_airport_id': instance.destinationAirportId,
      'departure_time': instance.departureTime.toIso8601String(),
      'arrival_time': instance.arrivalTime.toIso8601String(),
      'status': _$FlightStatusEnumMap[instance.status]!,
      'gate': instance.gate,
      'terminal': instance.terminal,
      'airplane_id': instance.airplaneId,
    };

FlightUpdate _$FlightUpdateFromJson(Map<String, dynamic> json) => FlightUpdate(
      departureTime: json['departure_time'] == null
          ? null
          : DateTime.parse(json['departure_time'] as String),
      arrivalTime: json['arrival_time'] == null
          ? null
          : DateTime.parse(json['arrival_time'] as String),
      status: $enumDecodeNullable(_$FlightStatusEnumMap, json['status']),
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
      airplaneId: json['airplane_id'] as String?,
    );

Map<String, dynamic> _$FlightUpdateToJson(FlightUpdate instance) =>
    <String, dynamic>{
      'departure_time': instance.departureTime?.toIso8601String(),
      'arrival_time': instance.arrivalTime?.toIso8601String(),
      'status': _$FlightStatusEnumMap[instance.status],
      'gate': instance.gate,
      'terminal': instance.terminal,
      'airplane_id': instance.airplaneId,
    };

FlightStatusUpdate _$FlightStatusUpdateFromJson(Map<String, dynamic> json) =>
    FlightStatusUpdate(
      status: $enumDecode(_$FlightStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$FlightStatusUpdateToJson(FlightStatusUpdate instance) =>
    <String, dynamic>{
      'status': _$FlightStatusEnumMap[instance.status]!,
    };

FlightGateTerminalUpdate _$FlightGateTerminalUpdateFromJson(
        Map<String, dynamic> json) =>
    FlightGateTerminalUpdate(
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
    );

Map<String, dynamic> _$FlightGateTerminalUpdateToJson(
        FlightGateTerminalUpdate instance) =>
    <String, dynamic>{
      'gate': instance.gate,
      'terminal': instance.terminal,
    };
