import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<User> updateProfile({
    required String token,
    String? phoneNumber,
    String? passportNumber,
    String? nationality,
    String? birthDate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (passportNumber != null) data['passport_number'] = passportNumber;
      if (nationality != null) data['nationality'] = nationality;
      if (birthDate != null) data['birth_date'] = birthDate;

      final response = await _dio.put(
        '${ApiConfig.baseUrl}${ApiConfig.usersProfile}',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllNotificationsAsRead({required String token}) async {
    try {
      await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.userNotificationsReadAll}',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['detail'] ?? 'Unknown error';
      return message.toString();
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}



