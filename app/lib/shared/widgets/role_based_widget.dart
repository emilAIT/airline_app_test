import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/enums.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget? passenger;
  final Widget? staff;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    this.passenger,
    this.staff,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          return fallback ?? const SizedBox.shrink();
        }

        if (authService.currentUser?.role == UserRole.PASSENGER && passenger != null) {
          return passenger!;
        }

        if (authService.currentUser?.role == UserRole.STAFF && staff != null) {
          return staff!;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

