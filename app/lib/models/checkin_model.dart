import 'package:json_annotation/json_annotation.dart';

part 'checkin_model.g.dart';

@JsonSerializable()
class CheckInPublic {
  final String id;
  final String ticketId;
  final DateTime checkedInAt;

  CheckInPublic({
    required this.id,
    required this.ticketId,
    required this.checkedInAt,
  });

  factory CheckInPublic.fromJson(Map<String, dynamic> json) =>
      _$CheckInPublicFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInPublicToJson(this);
}

@JsonSerializable()
class CheckInsPublic {
  final List<CheckInPublic> data;
  final int count;

  CheckInsPublic({
    required this.data,
    required this.count,
  });

  factory CheckInsPublic.fromJson(Map<String, dynamic> json) =>
      _$CheckInsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInsPublicToJson(this);
}

@JsonSerializable()
class CheckInCreate {
  final String ticketId;

  CheckInCreate({
    required this.ticketId,
  });

  factory CheckInCreate.fromJson(Map<String, dynamic> json) =>
      _$CheckInCreateFromJson(json);

  Map<String, dynamic> toJson() => _$CheckInCreateToJson(this);
}

@JsonSerializable()
class BoardingPassPublic {
  final String id;
  final String checkinId;
  final String seatNumber;
  final String? gate;
  final String? boardingGroup;
  final String qrCode;
  final DateTime createdAt;

  BoardingPassPublic({
    required this.id,
    required this.checkinId,
    required this.seatNumber,
    this.gate,
    this.boardingGroup,
    required this.qrCode,
    required this.createdAt,
  });

  factory BoardingPassPublic.fromJson(Map<String, dynamic> json) =>
      _$BoardingPassPublicFromJson(json);

  Map<String, dynamic> toJson() => _$BoardingPassPublicToJson(this);
}

