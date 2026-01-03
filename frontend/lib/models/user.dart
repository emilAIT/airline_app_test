enum UserRole { passenger, staff }

class User {
  final int id;
  final String email;
  final UserRole role;
  final PassengerProfile? profile;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'] == 'STAFF' ? UserRole.staff : UserRole.passenger,
      profile: json['profile'] != null
          ? PassengerProfile.fromJson(json['profile'])
          : null,
    );
  }
}

class PassengerProfile {
  final String? fullName;
  final String? phone;
  final String? passportNumber;
  final String? nationality;
  final DateTime? dateOfBirth;

  PassengerProfile({
    this.fullName,
    this.phone,
    this.passportNumber,
    this.nationality,
    this.dateOfBirth,
  });

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      passportNumber: json['passport_number'] as String?,
      nationality: json['nationality'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
    );
  }
}
