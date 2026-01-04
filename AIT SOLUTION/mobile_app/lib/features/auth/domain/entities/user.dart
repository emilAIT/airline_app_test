import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String email;
  final String role;
  final String? status;
  final String? firstName;
  final String? lastName;
  final DateTime? createdAt;

  const User({
    this.id,
    required this.email,
    required this.role,
    this.status,
    this.firstName,
    this.lastName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, role, status, firstName, lastName, createdAt];
}
