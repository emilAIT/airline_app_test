import 'enums.dart';

class User {
  final int id;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      email: json['email'] as String,
      role: (json['role'] is String) 
          ? UserRole.fromJson(json['role'] as String)
          : UserRole.fromJson(json['role'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toJson(),
    };
  }
  
  bool get isPassenger => role == UserRole.PASSENGER;
  bool get isStaff => role == UserRole.STAFF;
}

