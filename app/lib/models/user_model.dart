import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserPublic {
  final String id;
  final String email;
  final bool isActive;
  final String? fullName;
  final UserRole role;

  UserPublic({
    required this.id,
    required this.email,
    this.isActive = true,
    this.fullName,
    this.role = UserRole.passenger,
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) =>
      _$UserPublicFromJson(json);

  Map<String, dynamic> toJson() => _$UserPublicToJson(this);
}

enum UserRole {
  @JsonValue('PASSENGER')
  passenger,
  @JsonValue('STAFF')
  staff,
}

@JsonSerializable()
class Token {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type', defaultValue: 'bearer')
  final String tokenType;

  Token({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);
}

@JsonSerializable()
class UserRegister {
  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'passport_number')
  final String passportNumber;
  final String nationality;
  @JsonKey(name: 'date_of_birth')
  final String dateOfBirth;

  UserRegister({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.passportNumber,
    required this.nationality,
    required this.dateOfBirth,
  });

  factory UserRegister.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterFromJson(json);

  Map<String, dynamic> toJson() => _$UserRegisterToJson(this);
}

@JsonSerializable()
class PassengerProfilePublic {
  final String id;
  final String userId;
  final String phoneNumber;
  final String passportNumber;
  final String nationality;
  final String dateOfBirth;

  PassengerProfilePublic({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.passportNumber,
    required this.nationality,
    required this.dateOfBirth,
  });

  factory PassengerProfilePublic.fromJson(Map<String, dynamic> json) =>
      _$PassengerProfilePublicFromJson(json);

  Map<String, dynamic> toJson() => _$PassengerProfilePublicToJson(this);
}

@JsonSerializable()
class UsersPublic {
  final List<UserPublic> data;
  final int count;

  UsersPublic({
    required this.data,
    required this.count,
  });

  factory UsersPublic.fromJson(Map<String, dynamic> json) =>
      _$UsersPublicFromJson(json);

  Map<String, dynamic> toJson() => _$UsersPublicToJson(this);
}

@JsonSerializable()
class UserCreate {
  final String email;
  final String password;
  final String? fullName;
  final bool isActive;
  final UserRole role;

  UserCreate({
    required this.email,
    required this.password,
    this.fullName,
    this.isActive = true,
    this.role = UserRole.passenger,
  });

  factory UserCreate.fromJson(Map<String, dynamic> json) =>
      _$UserCreateFromJson(json);

  Map<String, dynamic> toJson() => _$UserCreateToJson(this);
}

@JsonSerializable()
class UserUpdate {
  final String? email;
  final String? password;
  final String? fullName;
  final bool? isActive;
  final UserRole? role;

  UserUpdate({
    this.email,
    this.password,
    this.fullName,
    this.isActive,
    this.role,
  });

  factory UserUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UserUpdateToJson(this);
}

