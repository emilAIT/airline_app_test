// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airport_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AirportPublic _$AirportPublicFromJson(Map<String, dynamic> json) =>
    AirportPublic(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
    );

Map<String, dynamic> _$AirportPublicToJson(AirportPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'city': instance.city,
      'country': instance.country,
    };

AirportsPublic _$AirportsPublicFromJson(Map<String, dynamic> json) =>
    AirportsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => AirportPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AirportsPublicToJson(AirportsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

AirportCreate _$AirportCreateFromJson(Map<String, dynamic> json) =>
    AirportCreate(
      code: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
    );

Map<String, dynamic> _$AirportCreateToJson(AirportCreate instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'city': instance.city,
      'country': instance.country,
    };

AirportUpdate _$AirportUpdateFromJson(Map<String, dynamic> json) =>
    AirportUpdate(
      code: json['code'] as String?,
      name: json['name'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$AirportUpdateToJson(AirportUpdate instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'city': instance.city,
      'country': instance.country,
    };
