// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketPublic _$TicketPublicFromJson(Map<String, dynamic> json) => TicketPublic(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String,
      bookingId: json['booking_id'] as String,
      flightSeatId: json['flight_seat_id'] as String?,
      passengerName: json['passenger_name'] as String,
      seatNumber: json['seat_number'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TicketPublicToJson(TicketPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_number': instance.ticketNumber,
      'booking_id': instance.bookingId,
      'flight_seat_id': instance.flightSeatId,
      'passenger_name': instance.passengerName,
      'seat_number': instance.seatNumber,
      'created_at': instance.createdAt.toIso8601String(),
    };

TicketsPublic _$TicketsPublicFromJson(Map<String, dynamic> json) =>
    TicketsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => TicketPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$TicketsPublicToJson(TicketsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };
