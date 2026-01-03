// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementPublic _$AnnouncementPublicFromJson(Map<String, dynamic> json) =>
    AnnouncementPublic(
      id: json['id'] as String,
      flightId: json['flight_id'] as String,
      type: $enumDecode(_$AnnouncementTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByUserId: json['created_by_user_id'] as String?,
    );

Map<String, dynamic> _$AnnouncementPublicToJson(AnnouncementPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'flight_id': instance.flightId,
      'type': _$AnnouncementTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'created_at': instance.createdAt.toIso8601String(),
      'created_by_user_id': instance.createdByUserId,
    };

const _$AnnouncementTypeEnumMap = {
  AnnouncementType.delay: 'DELAY',
  AnnouncementType.cancellation: 'CANCELLATION',
  AnnouncementType.gateChange: 'GATE_CHANGE',
  AnnouncementType.boardingStarted: 'BOARDING_STARTED',
  AnnouncementType.general: 'GENERAL',
};

AnnouncementsPublic _$AnnouncementsPublicFromJson(Map<String, dynamic> json) =>
    AnnouncementsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => AnnouncementPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AnnouncementsPublicToJson(
        AnnouncementsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

AnnouncementCreate _$AnnouncementCreateFromJson(Map<String, dynamic> json) =>
    AnnouncementCreate(
      flightId: json['flight_id'] as String,
      type: $enumDecode(_$AnnouncementTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$AnnouncementCreateToJson(AnnouncementCreate instance) =>
    <String, dynamic>{
      'flight_id': instance.flightId,
      'type': _$AnnouncementTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
    };

AnnouncementUpdate _$AnnouncementUpdateFromJson(Map<String, dynamic> json) =>
    AnnouncementUpdate(
      type: $enumDecodeNullable(_$AnnouncementTypeEnumMap, json['type']),
      title: json['title'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AnnouncementUpdateToJson(AnnouncementUpdate instance) =>
    <String, dynamic>{
      'type': _$AnnouncementTypeEnumMap[instance.type],
      'title': instance.title,
      'message': instance.message,
    };
