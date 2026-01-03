import 'package:equatable/equatable.dart';

enum UserRole {
  passenger,
  staff,
}

class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final UserRole role;
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, username, email, role, isActive];
}
