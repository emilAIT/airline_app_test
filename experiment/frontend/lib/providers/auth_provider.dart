import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/staff_service.dart';
import '../services/notification_service.dart';
import 'package:dio/dio.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // Не устанавливаем baseUrl здесь, так как сервисы используют полные URL с ApiConfig.baseUrl
  // Увеличены таймауты для мобильных устройств
  dio.options.connectTimeout = const Duration(seconds: 60);
  dio.options.receiveTimeout = const Duration(seconds: 60);
  return dio;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final staffServiceProvider = Provider<StaffService>((ref) {
  final authState = ref.watch(authProvider);
  return StaffService(ref.read(dioProvider), token: authState.token);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider));
});

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => token != null && user != null;
  
  bool get isStaff {
    final role = user?.role?.toLowerCase().trim();
    print('[AUTH_STATE] isStaff check: role="$role", result=${role == 'staff'}');
    return role == 'staff';
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final StorageService _storageService;
  bool _initialized = false;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() => _loadSavedToken());
    }
    // Set initial state to loading so AuthWrapper shows spinner
    // until _loadSavedToken completes
    return AuthState(isLoading: true);
  }

  Future<void> _loadSavedToken() async {
    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        print('[AUTH_PROVIDER] Found saved token, loading user...');
        try {
          final user = await _authService.getCurrentUser(token);
          print('[AUTH_PROVIDER] User loaded from saved token: ${user.email}');
          state = state.copyWith(token: token, user: user, isLoading: false);
        } catch (e) {
          print('[AUTH_PROVIDER] Saved token is invalid, clearing storage: $e');
          await _storageService.clearAll();
          state = state.copyWith(token: null, user: null, isLoading: false);
        }
      } else {
        print('[AUTH_PROVIDER] No saved token found');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('[AUTH_PROVIDER] Error loading saved token: $e');
      await _storageService.clearAll();
      state = state.copyWith(token: null, user: null, isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    print('[AUTH_PROVIDER] Starting login for: $email');
    
    // Полностью очищаем предыдущее состояние и токен перед новым логином
    await _storageService.clearAll();
    // Сначала устанавливаем пустое состояние с isLoading
    state = AuthState(isLoading: true, error: null, token: null, user: null);
    
    try {
      final tokenResponse = await _authService.login(email, password);
      print('[AUTH_PROVIDER] Token received, length: ${tokenResponse.accessToken.length}');
      
      final user = await _authService.getCurrentUser(tokenResponse.accessToken);
      print('[AUTH_PROVIDER] User retrieved: ${user.email}, role: ${user.role}');
      
      // Сохраняем новый токен и email
      await _storageService.saveToken(tokenResponse.accessToken);
      await _storageService.saveUserEmail(email);
      print('[AUTH_PROVIDER] Token and email saved to storage');
      
      // Устанавливаем новое состояние с токеном и пользователем
      state = AuthState(
        token: tokenResponse.accessToken,
        user: user,
        isLoading: false,
        error: null,
      );
      print('[AUTH_PROVIDER] Login successful, state updated with token and user');
      print('[AUTH_PROVIDER] Final state: isAuthenticated=${state.isAuthenticated}, isStaff=${state.isStaff}');
    } catch (e) {
      print('[AUTH_PROVIDER] Login failed: $e');
      String errorMessage = e.toString();
      // Убираем префикс "Exception: " если он есть
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      // При ошибке полностью очищаем состояние и хранилище
      await _storageService.clearAll();
      state = AuthState(
        isLoading: false,
        error: errorMessage,
        token: null,
        user: null,
      );
      print('[AUTH_PROVIDER] Error state set: $errorMessage, storage cleared');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      // После регистрации автоматически логинимся
      await login(email, password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    print('[AUTH_PROVIDER] Logging out');
    // Сначала очищаем хранилище
    await _storageService.clearAll();
    // Затем полностью сбрасываем состояние - все поля в null/false
    state = AuthState(
      token: null,
      user: null,
      isLoading: false,
      error: null,
    );
    print('[AUTH_PROVIDER] Logout completed, state and storage cleared');
    // Убеждаемся, что состояние обновилось
    await Future.delayed(const Duration(milliseconds: 50));
    print('[AUTH_PROVIDER] State after logout: token=${state.token}, user=${state.user?.email}, isAuthenticated=${state.isAuthenticated}');
  }

  Future<void> refreshUser() async {
    if (state.token != null) {
      try {
        final user = await _authService.getCurrentUser(state.token!);
        state = state.copyWith(user: user);
      } catch (e) {
        await logout();
      }
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
