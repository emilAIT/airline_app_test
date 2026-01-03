import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/services/auth_service.dart';
import 'router.dart';
import 'theme.dart';

class AirlineApp extends StatelessWidget {
  const AirlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airline Booking System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return Consumer<AuthService>(
          builder: (context, authService, _) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

