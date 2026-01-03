class User {
  final int id;
  final String email;
  final String? fullName;
  final String role;
  final bool isActive;
  final PassengerProfile? profile;

  User({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      isActive: json['is_active'],
      profile: json['profile'] != null
          ? PassengerProfile.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'profile': profile?.toJson(),
    };
  }
}

class PassengerProfile {
  final int id;
  final int userId;
  final String? phoneNumber;
  final String? passportNumber;
  final String? nationality;
  final String? birthDate;

  PassengerProfile({
    required this.id,
    required this.userId,
    this.phoneNumber,
    this.passportNumber,
    this.nationality,
    this.birthDate,
  });

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
      passportNumber: json['passport_number'],
      nationality: json['nationality'],
      birthDate: json['birth_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'passport_number': passportNumber,
      'nationality': nationality,
      'birth_date': birthDate,
    };
  }

  bool get isComplete {
    return phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        passportNumber != null &&
        passportNumber!.isNotEmpty &&
        nationality != null &&
        nationality!.isNotEmpty &&
        birthDate != null &&
        birthDate!.isNotEmpty;
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}



