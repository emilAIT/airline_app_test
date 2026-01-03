import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;
  
  UserService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<UserPublic>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/users/',
        queryParams: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = UsersPublic.fromJson(jsonDecode(response.body));
        return data.data;
      } else {
        throw Exception('Failed to get users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get users error: $e');
    }
  }

  Future<UserPublic> getUser(String userId) async {
    try {
      final response = await _apiService.get(
        '/users/$userId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return UserPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  Future<UserPublic> createUser(UserCreate userCreate) async {
    try {
      final response = await _apiService.post(
        '/users/',
        body: userCreate.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return UserPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create user error: $e');
    }
  }

  Future<UserPublic> updateUser(String userId, UserUpdate update) async {
    try {
      final response = await _apiService.patch(
        '/users/$userId',
        body: update.toJson(),
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return UserPublic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update user error: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await _apiService.delete(
        '/users/$userId',
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete user error: $e');
    }
  }
}

