import 'package:json_annotation/json_annotation.dart';

part 'announcement_model.g.dart';

enum AnnouncementType {
  @JsonValue('DELAY')
  delay,
  @JsonValue('CANCELLATION')
  cancellation,
  @JsonValue('GATE_CHANGE')
  gateChange,
  @JsonValue('BOARDING_STARTED')
  boardingStarted,
  @JsonValue('GENERAL')
  general,
}

@JsonSerializable()
class AnnouncementPublic {
  final String id;
  @JsonKey(name: 'flight_id')
  final String flightId;
  final AnnouncementType type;
  final String title;
  final String message;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'created_by_user_id')
  final String? createdByUserId;

  AnnouncementPublic({
    required this.id,
    required this.flightId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.createdByUserId,
  });

  factory AnnouncementPublic.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementPublicFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementPublicToJson(this);
}

@JsonSerializable()
class AnnouncementsPublic {
  final List<AnnouncementPublic> data;
  final int count;

  AnnouncementsPublic({
    required this.data,
    required this.count,
  });

  factory AnnouncementsPublic.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementsPublicToJson(this);
}

@JsonSerializable()
class AnnouncementCreate {
  @JsonKey(name: 'flight_id')
  final String flightId;
  final AnnouncementType type;
  final String title;
  final String message;

  AnnouncementCreate({
    required this.flightId,
    required this.type,
    required this.title,
    required this.message,
  });

  factory AnnouncementCreate.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementCreateToJson(this);
}

@JsonSerializable()
class AnnouncementUpdate {
  final AnnouncementType? type;
  final String? title;
  final String? message;

  AnnouncementUpdate({
    this.type,
    this.title,
    this.message,
  });

  factory AnnouncementUpdate.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementUpdateToJson(this);
}

