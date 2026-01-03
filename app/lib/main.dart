import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/flight_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/flight_cubit.dart';
import 'presentation/cubits/booking_cubit.dart';
import 'data/repositories/staff_repository.dart';
import 'presentation/cubits/staff_cubit.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/auth_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiClient = ApiClient();
  
  // Repositories
  final authRepository = AuthRepositoryImpl(apiClient);
  final profileRepository = ProfileRepositoryImpl(apiClient);
  final flightRepository = FlightRepositoryImpl(apiClient);
  final bookingRepository = BookingRepositoryImpl(apiClient);
  final staffRepository = StaffRepositoryImpl(apiClient);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<ProfileRepository>(create: (_) => profileRepository),
        RepositoryProvider<FlightRepository>(create: (_) => flightRepository),
        RepositoryProvider<BookingRepository>(create: (_) => bookingRepository),
        RepositoryProvider<StaffRepository>(create: (_) => staffRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit(authRepository, profileRepository)..checkAuth()),
          BlocProvider(create: (context) => FlightCubit(flightRepository)),
          BlocProvider(create: (context) => BookingCubit(bookingRepository)),
          BlocProvider(create: (context) => StaffCubit(staffRepository)),
        ],
        child: const AirlineApp(),
      ),
    ),
  );
}

class AirlineApp extends StatelessWidget {
  const AirlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AITS Airline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}
