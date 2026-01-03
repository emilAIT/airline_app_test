import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<UserNotification>> getNotifications({
    required String token,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.userNotifications}',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return (response.data as List)
          .map((json) => UserNotification.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.userNotificationsUnreadCount}',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['unread_count'] as int;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserNotification> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.baseUrl}${ApiConfig.userNotificationMarkRead}/$notificationId/read',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return UserNotification.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> markAllAsRead({
    required String token,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.baseUrl}${ApiConfig.userNotificationsReadAll}',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data as Map<String, dynamic>;
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



