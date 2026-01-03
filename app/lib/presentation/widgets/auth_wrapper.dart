import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/presentation/cubits/auth_cubit.dart';
import 'package:airline_app/domain/entities/user.dart';
import 'package:airline_app/presentation/screens/auth/login_screen.dart';
import 'package:airline_app/presentation/screens/profile/profile_completion_screen.dart';
import 'package:airline_app/presentation/screens/home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Authenticated) {
          // If passenger, check if profile is complete
          if (state.user.role == UserRole.passenger && !state.isProfileComplete) {
            return const ProfileCompletionScreen();
          }
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
