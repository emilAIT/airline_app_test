import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/passenger_main_screen.dart';
import 'screens/staff_main_screen.dart';
import 'providers/auth_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turkish Airlines',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Debug prints (only in debug mode)
    if (kDebugMode) {
      print('[AUTH_WRAPPER] isLoading: ${authState.isLoading}');
      print('[AUTH_WRAPPER] isAuthenticated: ${authState.isAuthenticated}');
      print('[AUTH_WRAPPER] user: ${authState.user?.email}');
      print('[AUTH_WRAPPER] role: ${authState.user?.role}');
      print('[AUTH_WRAPPER] isStaff: ${authState.isStaff}');
    }

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Check if user is staff
    if (authState.isStaff) {
      print('[AUTH_WRAPPER] Navigating to StaffMainScreen');
      return const StaffMainScreen();
    }

    print('[AUTH_WRAPPER] Navigating to PassengerMainScreen');
    return const PassengerMainScreen();
  }
}
