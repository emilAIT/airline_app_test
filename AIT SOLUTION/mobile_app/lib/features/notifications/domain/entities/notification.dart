import 'package:equatable/equatable.dart';

enum NotificationType {
  bookingCreated('booking_created'),
  bookingPaid('booking_paid'),
  bookingExpired('booking_expired'),
  bookingCancelled('booking_cancelled'),
  flightUpdate('flight_update'),
  flightDelayed('flight_delayed'),
  flightCancelled('flight_cancelled'),
  staffAnnouncement('staff_announcement'),
  unknown('unknown');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.unknown,
    );
  }
}

class NotificationEntity extends Equatable {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int? bookingId;
  final int? flightId;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
    this.flightId,
  });

  @override
  List<Object?> get props => [
    id, type, title, message, isRead, createdAt, bookingId, flightId
  ];
}
