// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airplane_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AirplanePublic _$AirplanePublicFromJson(Map<String, dynamic> json) =>
    AirplanePublic(
      id: json['id'] as String,
      model: json['model'] as String,
      totalSeats: (json['total_seats'] as num).toInt(),
    );

Map<String, dynamic> _$AirplanePublicToJson(AirplanePublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'model': instance.model,
      'total_seats': instance.totalSeats,
    };

SeatTemplateBase _$SeatTemplateBaseFromJson(Map<String, dynamic> json) =>
    SeatTemplateBase(
      row: (json['row'] as num).toInt(),
      seatLabel: json['seat_label'] as String,
      category: $enumDecodeNullable(_$SeatCategoryEnumMap, json['category']) ??
          SeatCategory.standard,
    );

Map<String, dynamic> _$SeatTemplateBaseToJson(SeatTemplateBase instance) =>
    <String, dynamic>{
      'row': instance.row,
      'seat_label': instance.seatLabel,
      'category': _$SeatCategoryEnumMap[instance.category]!,
    };

const _$SeatCategoryEnumMap = {
  SeatCategory.standard: 'STANDARD',
  SeatCategory.extraLegroom: 'EXTRA_LEGROOM',
};

AirplaneCreateRequest _$AirplaneCreateRequestFromJson(
        Map<String, dynamic> json) =>
    AirplaneCreateRequest(
      model: json['model'] as String,
      seatMap: (json['seat_map'] as List<dynamic>)
          .map((e) => SeatTemplateBase.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AirplaneCreateRequestToJson(
        AirplaneCreateRequest instance) =>
    <String, dynamic>{
      'model': instance.model,
      'seat_map': instance.seatMap,
    };

AirplaneUpdate _$AirplaneUpdateFromJson(Map<String, dynamic> json) =>
    AirplaneUpdate(
      model: json['model'] as String?,
    );

Map<String, dynamic> _$AirplaneUpdateToJson(AirplaneUpdate instance) =>
    <String, dynamic>{
      'model': instance.model,
    };

AirplaneSeatMapResponse _$AirplaneSeatMapResponseFromJson(
        Map<String, dynamic> json) =>
    AirplaneSeatMapResponse(
      airplaneId: json['airplane_id'] as String,
      model: json['model'] as String,
      totalSeats: (json['total_seats'] as num).toInt(),
      seatMap: (json['seat_map'] as List<dynamic>)
          .map((e) => SeatTemplateBase.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AirplaneSeatMapResponseToJson(
        AirplaneSeatMapResponse instance) =>
    <String, dynamic>{
      'airplane_id': instance.airplaneId,
      'model': instance.model,
      'total_seats': instance.totalSeats,
      'seat_map': instance.seatMap,
    };
