// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckInPublic _$CheckInPublicFromJson(Map<String, dynamic> json) =>
    CheckInPublic(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      checkedInAt: DateTime.parse(json['checkedInAt'] as String),
    );

Map<String, dynamic> _$CheckInPublicToJson(CheckInPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticketId': instance.ticketId,
      'checkedInAt': instance.checkedInAt.toIso8601String(),
    };

CheckInsPublic _$CheckInsPublicFromJson(Map<String, dynamic> json) =>
    CheckInsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => CheckInPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CheckInsPublicToJson(CheckInsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

CheckInCreate _$CheckInCreateFromJson(Map<String, dynamic> json) =>
    CheckInCreate(
      ticketId: json['ticketId'] as String,
    );

Map<String, dynamic> _$CheckInCreateToJson(CheckInCreate instance) =>
    <String, dynamic>{
      'ticketId': instance.ticketId,
    };

BoardingPassPublic _$BoardingPassPublicFromJson(Map<String, dynamic> json) =>
    BoardingPassPublic(
      id: json['id'] as String,
      checkinId: json['checkinId'] as String,
      seatNumber: json['seatNumber'] as String,
      gate: json['gate'] as String?,
      boardingGroup: json['boardingGroup'] as String?,
      qrCode: json['qrCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BoardingPassPublicToJson(BoardingPassPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'checkinId': instance.checkinId,
      'seatNumber': instance.seatNumber,
      'gate': instance.gate,
      'boardingGroup': instance.boardingGroup,
      'qrCode': instance.qrCode,
      'createdAt': instance.createdAt.toIso8601String(),
    };
