// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPublic _$UserPublicFromJson(Map<String, dynamic> json) => UserPublic(
      id: json['id'] as String,
      email: json['email'] as String,
      isActive: json['isActive'] as bool? ?? true,
      fullName: json['fullName'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.passenger,
    );

Map<String, dynamic> _$UserPublicToJson(UserPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'isActive': instance.isActive,
      'fullName': instance.fullName,
      'role': _$UserRoleEnumMap[instance.role]!,
    };

const _$UserRoleEnumMap = {
  UserRole.passenger: 'PASSENGER',
  UserRole.staff: 'STAFF',
};

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
    };

UserRegister _$UserRegisterFromJson(Map<String, dynamic> json) => UserRegister(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      passportNumber: json['passport_number'] as String,
      nationality: json['nationality'] as String,
      dateOfBirth: json['date_of_birth'] as String,
    );

Map<String, dynamic> _$UserRegisterToJson(UserRegister instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'full_name': instance.fullName,
      'phone_number': instance.phoneNumber,
      'passport_number': instance.passportNumber,
      'nationality': instance.nationality,
      'date_of_birth': instance.dateOfBirth,
    };

PassengerProfilePublic _$PassengerProfilePublicFromJson(
        Map<String, dynamic> json) =>
    PassengerProfilePublic(
      id: json['id'] as String,
      userId: json['userId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      passportNumber: json['passportNumber'] as String,
      nationality: json['nationality'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
    );

Map<String, dynamic> _$PassengerProfilePublicToJson(
        PassengerProfilePublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'phoneNumber': instance.phoneNumber,
      'passportNumber': instance.passportNumber,
      'nationality': instance.nationality,
      'dateOfBirth': instance.dateOfBirth,
    };

UsersPublic _$UsersPublicFromJson(Map<String, dynamic> json) => UsersPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => UserPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$UsersPublicToJson(UsersPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) => UserCreate(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.passenger,
    );

Map<String, dynamic> _$UserCreateToJson(UserCreate instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
      'role': _$UserRoleEnumMap[instance.role]!,
    };

UserUpdate _$UserUpdateFromJson(Map<String, dynamic> json) => UserUpdate(
      email: json['email'] as String?,
      password: json['password'] as String?,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$UserUpdateToJson(UserUpdate instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
      'role': _$UserRoleEnumMap[instance.role],
    };
