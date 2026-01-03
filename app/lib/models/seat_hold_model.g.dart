// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat_hold_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeatHoldPublic _$SeatHoldPublicFromJson(Map<String, dynamic> json) =>
    SeatHoldPublic(
      id: json['id'] as String,
      flightId: json['flightId'] as String,
      flightSeatId: json['flightSeatId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$SeatHoldPublicToJson(SeatHoldPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'flightId': instance.flightId,
      'flightSeatId': instance.flightSeatId,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

SeatHoldsPublic _$SeatHoldsPublicFromJson(Map<String, dynamic> json) =>
    SeatHoldsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => SeatHoldPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$SeatHoldsPublicToJson(SeatHoldsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

SeatHoldCreate _$SeatHoldCreateFromJson(Map<String, dynamic> json) =>
    SeatHoldCreate(
      flightId: json['flightId'] as String,
      flightSeatId: json['flightSeatId'] as String,
    );

Map<String, dynamic> _$SeatHoldCreateToJson(SeatHoldCreate instance) =>
    <String, dynamic>{
      'flightId': instance.flightId,
      'flightSeatId': instance.flightSeatId,
    };
