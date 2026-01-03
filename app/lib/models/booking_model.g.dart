// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingPublic _$BookingPublicFromJson(Map<String, dynamic> json) =>
    BookingPublic(
      id: json['id'] as String,
      pnr: json['pnr'] as String,
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      flightId: json['flight_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BookingPublicToJson(BookingPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pnr': instance.pnr,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'flight_id': instance.flightId,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.created: 'CREATED',
  BookingStatus.confirmed: 'CONFIRMED',
  BookingStatus.cancelled: 'CANCELLED',
};

BookingsPublic _$BookingsPublicFromJson(Map<String, dynamic> json) =>
    BookingsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => BookingPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$BookingsPublicToJson(BookingsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

BookingCreate _$BookingCreateFromJson(Map<String, dynamic> json) =>
    BookingCreate(
      flightId: json['flight_id'] as String,
      passengers: (json['passengers'] as List<dynamic>)
          .map((e) => BookingPassenger.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookingCreateToJson(BookingCreate instance) =>
    <String, dynamic>{
      'flight_id': instance.flightId,
      'passengers': instance.passengers,
    };

BookingPassenger _$BookingPassengerFromJson(Map<String, dynamic> json) =>
    BookingPassenger(
      passengerName: json['passenger_name'] as String,
      seatId: json['seat_id'] as String?,
    );

Map<String, dynamic> _$BookingPassengerToJson(BookingPassenger instance) =>
    <String, dynamic>{
      'passenger_name': instance.passengerName,
      'seat_id': instance.seatId,
    };
