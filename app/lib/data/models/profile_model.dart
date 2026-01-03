import '../../domain/entities/passenger_profile.dart';
import 'package:intl/intl.dart';

class ProfileModel extends PassengerProfile {
  const ProfileModel({
    required super.id,
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.passportNumber,
    required super.dateOfBirth,
    required super.nationality,
    super.phoneNumber,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      passportNumber: json['passport_number'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      nationality: json['nationality'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'passport_number': passportNumber,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(dateOfBirth),
      'nationality': nationality,
      'phone_number': phoneNumber,
    };
  }
}
