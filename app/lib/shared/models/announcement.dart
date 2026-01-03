import 'enums.dart';

class Announcement {
  final int id;
  final int flightId;
  final AnnouncementType type;
  final String title;
  final String message;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.flightId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] as num).toInt(),
      flightId: (json['flight_id'] as num).toInt(),
      type: AnnouncementType.fromJson(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flight_id': flightId,
      'type': type.toJson(),
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

