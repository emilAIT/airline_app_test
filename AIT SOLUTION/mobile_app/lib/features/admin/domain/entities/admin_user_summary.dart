import 'package:equatable/equatable.dart';

class AdminUserSummary extends Equatable {
  final int id;
  final String email;
  final String role;
  final String status;
  final String? firstName;
  final String? lastName;
  final List<LinkedItem> flights;
  final List<LinkedItem> airplanes;

  const AdminUserSummary({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.firstName,
    this.lastName,
    this.flights = const [],
    this.airplanes = const [],
  });

  @override
  List<Object?> get props => [id, email, role, status, firstName, lastName, flights, airplanes];
}

class LinkedItem extends Equatable {
  final int id;
  final String label;
  const LinkedItem({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}

