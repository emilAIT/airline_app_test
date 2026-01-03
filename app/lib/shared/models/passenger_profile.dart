class PassengerProfile {
  final int id;
  final int userId;
  final String? fullName;
  final String? phoneNumber;
  final String? passportNumber;
  final String? nationality;
  final DateTime? dateOfBirth;
  final bool isComplete;

  PassengerProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.phoneNumber,
    this.passportNumber,
    this.nationality,
    this.dateOfBirth,
    required this.isComplete,
  });

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      passportNumber: json['passport_number'] as String?,
      nationality: json['nationality'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      isComplete: json['is_complete'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'passport_number': passportNumber,
      'nationality': nationality,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'is_complete': isComplete,
    };
  }
}

