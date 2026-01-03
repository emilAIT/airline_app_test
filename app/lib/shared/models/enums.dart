// ignore_for_file: constant_identifier_names

enum UserRole {
  PASSENGER,
  STAFF;

  String toJson() => name;
  
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.PASSENGER,
    );
  }
}

enum BookingStatus {
  CREATED,
  CONFIRMED,
  CANCELLED;

  String toJson() => name;
  
  static BookingStatus fromJson(String value) {
    return BookingStatus.values.firstWhere((e) => e.name == value);
  }
}

enum FlightStatus {
  SCHEDULED,
  BOARDING,
  DELAYED,
  CANCELLED,
  DEPARTED,
  LANDED;

  String toJson() => name;
  
  static FlightStatus fromJson(String value) {
    return FlightStatus.values.firstWhere((e) => e.name == value);
  }
}

enum PaymentStatus {
  PENDING,
  PAID,
  FAILED;

  String toJson() => name;
  
  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere((e) => e.name == value);
  }
}

enum PaymentMethod {
  CARD,
  APPLE_PAY,
  GOOGLE_PAY;

  String toJson() => name;
  
  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere((e) => e.name == value);
  }
  
  String get displayName {
    switch (this) {
      case PaymentMethod.CARD:
        return 'Credit/Debit Card';
      case PaymentMethod.APPLE_PAY:
        return 'Apple Pay';
      case PaymentMethod.GOOGLE_PAY:
        return 'Google Pay';
    }
  }
}

enum SeatCategory {
  STANDARD,
  EXTRA_LEGROOM;

  String toJson() => name;
  
  static SeatCategory fromJson(String value) {
    return SeatCategory.values.firstWhere((e) => e.name == value);
  }
  
  String get displayName {
    switch (this) {
      case SeatCategory.STANDARD:
        return 'Standard';
      case SeatCategory.EXTRA_LEGROOM:
        return 'Extra Legroom';
    }
  }
}

enum AnnouncementType {
  DELAY,
  CANCELLATION,
  GATE_CHANGE,
  BOARDING_STARTED,
  GENERAL;

  String toJson() => name;
  
  static AnnouncementType fromJson(String value) {
    return AnnouncementType.values.firstWhere((e) => e.name == value);
  }
  
  String get displayName {
    switch (this) {
      case AnnouncementType.DELAY:
        return 'Delay';
      case AnnouncementType.CANCELLATION:
        return 'Cancellation';
      case AnnouncementType.GATE_CHANGE:
        return 'Gate Change';
      case AnnouncementType.BOARDING_STARTED:
        return 'Boarding Started';
      case AnnouncementType.GENERAL:
        return 'General Information';
    }
  }
}

