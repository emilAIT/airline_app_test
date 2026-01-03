import 'package:equatable/equatable.dart';

class PassengerProfile extends Equatable {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String passportNumber;
  final DateTime dateOfBirth;
  final String nationality;
  final String? phoneNumber;

  const PassengerProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.passportNumber,
    required this.dateOfBirth,
    required this.nationality,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName';

  bool get isComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        passportNumber.isNotEmpty &&
        nationality.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        passportNumber,
        dateOfBirth,
        nationality,
        phoneNumber,
      ];
}
