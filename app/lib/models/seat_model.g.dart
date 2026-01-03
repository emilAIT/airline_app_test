// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlightSeat _$FlightSeatFromJson(Map<String, dynamic> json) => FlightSeat(
      id: json['id'] as String,
      flightId: json['flight_id'] as String,
      row: (json['row'] as num).toInt(),
      seatLabel: json['seat_label'] as String,
      category: $enumDecode(_$SeatCategoryEnumMap, json['category']),
      price: (json['price'] as num).toInt(),
      status: $enumDecode(_$FlightSeatStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$FlightSeatToJson(FlightSeat instance) =>
    <String, dynamic>{
      'id': instance.id,
      'flight_id': instance.flightId,
      'row': instance.row,
      'seat_label': instance.seatLabel,
      'category': _$SeatCategoryEnumMap[instance.category]!,
      'price': instance.price,
      'status': _$FlightSeatStatusEnumMap[instance.status]!,
    };

const _$SeatCategoryEnumMap = {
  SeatCategory.standard: 'STANDARD',
  SeatCategory.extraLegroom: 'EXTRA_LEGROOM',
};

const _$FlightSeatStatusEnumMap = {
  FlightSeatStatus.available: 'AVAILABLE',
  FlightSeatStatus.booked: 'BOOKED',
  FlightSeatStatus.blocked: 'BLOCKED',
};

SeatMapResponse _$SeatMapResponseFromJson(Map<String, dynamic> json) =>
    SeatMapResponse(
      flightId: json['flight_id'] as String,
      flightNumber: json['flight_number'] as String,
      seats: (json['seats'] as List<dynamic>)
          .map((e) => FlightSeat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SeatMapResponseToJson(SeatMapResponse instance) =>
    <String, dynamic>{
      'flight_id': instance.flightId,
      'flight_number': instance.flightNumber,
      'seats': instance.seats,
    };
