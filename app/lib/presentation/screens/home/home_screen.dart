import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/presentation/cubits/auth_cubit.dart';
import 'package:airline_app/domain/entities/user.dart';
import 'package:airline_app/presentation/screens/passenger/passenger_dashboard.dart';
import 'package:airline_app/presentation/screens/staff/staff_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;

    if (state is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = state.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.role == UserRole.staff ? 'Staff Console' : 'AITS Airline'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user.role == UserRole.staff
          ? const StaffDashboard()
          : const PassengerDashboard(),
    );
  }
}
