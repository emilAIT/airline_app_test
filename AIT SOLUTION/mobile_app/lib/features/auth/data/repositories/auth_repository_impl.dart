import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  String _parseErrorDetail(dynamic data, String defaultMessage) {
    if (data == null) return defaultMessage;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        try {
          return detail.map((e) {
            if (e is Map && e.containsKey('msg')) {
              return e['msg'];
            }
            return e.toString();
          }).join(', ');
        } catch (_) {
          return detail.toString();
        }
      }
      return detail.toString();
    }
    if (data is String) return data;
    return defaultMessage;
  }

  @override
  Future<Either<Failure, TokenModel>> login(
      String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return Left(AuthFailure('Email and password cannot be empty'));
      }

      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenModel = TokenModel.fromJson(response.data);
        await _apiClient.setAuthToken(tokenModel.accessToken);
        return Right(tokenModel);
      } else {
        return Left(AuthFailure('Invalid credentials'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure('Invalid email or password'));
      }

      final detail =
          _parseErrorDetail(e.response?.data, 'Server error during login');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(ServerFailure(
            'Connection timeout. Please check your internet connection.'));
      }

      return Left(ServerFailure(detail));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TokenModel>> register(
    String email,
    String password,
    String role, {
    String? firstName,
    String? lastName,
    String? phone,
    String? passportNumber,
    String? nationality,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return Left(AuthFailure('Email and password cannot be empty'));
      }

      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'role': role,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'passport_number': passportNumber,
          'nationality': nationality,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenModel = TokenModel.fromJson(response.data);
        await _apiClient.setAuthToken(tokenModel.accessToken);
        return Right(tokenModel);
      } else {
        return Left(ServerFailure('Registration failed'));
      }
    } on DioException catch (e) {
      final detail = _parseErrorDetail(e.response?.data, 'Registration failed');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Left(ServerFailure(
            'Connection timeout. Please check your internet connection.'));
      }
      return Left(ServerFailure(detail));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.clearAuthToken();
  }

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserModel.fromJson(response.data));
      } else {
        return Left(ServerFailure('Failed to get current user'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure('Not authenticated'));
      }

      // Обработка ошибок подключения
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        // При ошибке подключения считаем пользователя неавторизованным
        // чтобы показать страницу логина
        return Left(AuthFailure('Connection error. Please check your internet connection and ensure backend is running.'));
      }

      final detail = _parseErrorDetail(e.response?.data, 'Server error');
      return Left(ServerFailure(detail));
    } catch (e) {
      // При любой другой ошибке также считаем неавторизованным
      return Left(AuthFailure('Unable to connect to server. Please try again later.'));
    }
  }
}
