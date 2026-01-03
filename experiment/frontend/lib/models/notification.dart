class UserNotification {
  final int id;
  final int userId;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    // Parse UTC time from backend and convert to local time for display (Kyrgyzstan UTC+6)
    DateTime createdAt;
    if (json['created_at'] is String) {
      final dateStr = json['created_at'] as String;
      DateTime utcTime;
      if (dateStr.endsWith('Z') || dateStr.contains('+') || dateStr.contains('-', 10)) {
        utcTime = DateTime.parse(dateStr).toUtc();
      } else {
        utcTime = DateTime.parse('${dateStr}Z').toUtc();
      }
      // Convert UTC to local time for display
      createdAt = utcTime.toLocal();
    } else {
      final utcTime = DateTime.parse(json['created_at'].toString()).toUtc();
      createdAt = utcTime.toLocal();
    }

    return UserNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      message: json['message'],
      createdAt: createdAt,
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  UserNotification copyWith({
    int? id,
    int? userId,
    String? type,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class UserNotificationType {
  static const String bookingConfirmed = 'Booking Confirmed';
  static const String ticketPurchased = 'Ticket Purchased';
  static const String flightUpdate = 'Flight Update';
}



