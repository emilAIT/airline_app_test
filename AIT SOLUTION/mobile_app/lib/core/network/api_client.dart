import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

@singleton
class ApiClient {
  final Dio dio;
  static const String _tokenKey = 'auth_token';
  bool _isInitialized = false;

  // Определяем базовый URL в зависимости от платформы
  static String get _baseUrl {
    if (kIsWeb) {
      // Для веб используем localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Для Android эмулятора используем 10.0.2.2 (специальный адрес для localhost хоста)
      // Для физического устройства замените на IP вашего компьютера
      return 'http://10.0.2.2:8000';
    } else {
      // Для iOS и других платформ используем localhost
      return 'http://localhost:8000';
    }
  }

  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),  // Увеличен таймаут
          receiveTimeout: const Duration(seconds: 15),  // Увеличен таймаут
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('DIO_LOG: $o'),
    ));
    
    // Добавляем интерцептор для обработки ошибок авторизации
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print('DIO_LOG: 401 Unauthorized - Token may be expired');
          // Очищаем токен при ошибке 401
          await clearAuthToken();
        }
        handler.next(error);
      },
      onRequest: (options, handler) async {
        // Проверяем, что токен установлен перед каждым запросом
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
          print('DIO_LOG: Added token to request: ${options.path}');
        }
        handler.next(options);
      },
    ));
  }

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      print('DIO_LOG: Initialized ApiClient with persisted token: ${token.substring(0, 10)}...');
    } else {
      print('DIO_LOG: No persisted token found');
    }
    _isInitialized = true;
  }

  Future<void> setAuthToken(String token) async {
    dio.options.headers['Authorization'] = 'Bearer $token';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('DIO_LOG: Token SAVED: Bearer ${token.substring(0, 10)}...');
  }

  Future<void> clearAuthToken() async {
    dio.options.headers.remove('Authorization');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('DIO_LOG: Token CLEARED');
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
