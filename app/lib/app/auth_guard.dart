import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/services/auth_service.dart';
import '../shared/models/enums.dart';
import 'router.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final UserRole? requiredRole;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Not authenticated
        if (!authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRouter.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check role if required
        if (requiredRole != null &&
            authService.currentUser?.role != requiredRole) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text('You do not have permission to access this page.'),
            ),
          );
        }

        return child;
      },
    );
  }
}

