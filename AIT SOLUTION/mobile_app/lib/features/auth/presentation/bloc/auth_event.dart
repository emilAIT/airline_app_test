import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? passportNumber;
  final String? nationality;
  final String role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.passportNumber,
    this.nationality,
    this.role = 'passenger',
  });

  @override
  List<Object> get props => [
        email,
        password,
        firstName,
        lastName,
        phone ?? '',
        passportNumber ?? '',
        nationality ?? '',
        role
      ];
}
