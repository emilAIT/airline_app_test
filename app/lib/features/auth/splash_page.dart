import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/auth_service.dart';
import '../../app/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = context.read<AuthService>();
    await authService.loadStoredAuth();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (authService.isAuthenticated) {
      if (authService.isPassenger) {
        Navigator.of(context).pushReplacementNamed(AppRouter.passengerHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.staffHome);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Airline Booking System',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

