import 'package:json_annotation/json_annotation.dart';

part 'airport_model.g.dart';

@JsonSerializable()
class AirportPublic {
  final String id;
  final String code;
  final String name;
  final String city;
  final String country;

  AirportPublic({
    required this.id,
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  factory AirportPublic.fromJson(Map<String, dynamic> json) =>
      _$AirportPublicFromJson(json);

  Map<String, dynamic> toJson() => _$AirportPublicToJson(this);
}

@JsonSerializable()
class AirportsPublic {
  final List<AirportPublic> data;
  final int count;

  AirportsPublic({
    required this.data,
    required this.count,
  });

  factory AirportsPublic.fromJson(Map<String, dynamic> json) =>
      _$AirportsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$AirportsPublicToJson(this);
}

@JsonSerializable()
class AirportCreate {
  final String code;
  final String name;
  final String city;
  final String country;

  AirportCreate({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  factory AirportCreate.fromJson(Map<String, dynamic> json) =>
      _$AirportCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AirportCreateToJson(this);
}

@JsonSerializable()
class AirportUpdate {
  final String? code;
  final String? name;
  final String? city;
  final String? country;

  AirportUpdate({
    this.code,
    this.name,
    this.city,
    this.country,
  });

  factory AirportUpdate.fromJson(Map<String, dynamic> json) =>
      _$AirportUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AirportUpdateToJson(this);
}

