import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';

/// Helper function to navigate to the correct home page based on user role
void navigateToHome(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  if (authState is AuthAuthenticated) {
    final role = authState.user.role;
    if (role == 'admin') {
      context.go('/admin');
    } else if (role == 'staff') {
      context.go('/staff');
    } else {
      context.go('/home');
    }
  } else {
    context.go('/home');
  }
}




