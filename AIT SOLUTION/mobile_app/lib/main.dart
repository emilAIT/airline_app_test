import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/flight/presentation/bloc/flight_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/airplane/presentation/bloc/airplane_bloc.dart';
import 'features/booking/presentation/bloc/booking_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  configureDependencies();
  
  // Ensure ApiClient is ready with persisted token
  await getIt<ApiClient>().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => getIt<NotificationBloc>(),
        ),
        BlocProvider<FlightBloc>(
          create: (context) => getIt<FlightBloc>(),
        ),
        BlocProvider<AirplaneBloc>(
          create: (context) => getIt<AirplaneBloc>(),
        ),
        BlocProvider<BookingBloc>(
          create: (context) => getIt<BookingBloc>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('AUTH STATE CHANGED: $state');
          if (state is AuthUnauthenticated) {
            print('User is unauthenticated, navigating to login');
            appRouter.go('/login');
          } else if (state is AuthAuthenticated) {
            print('User is authenticated, navigating to home');
            final role = state.user.role;
            if (role == 'admin') {
              appRouter.go('/admin');
            } else if (role == 'staff') {
              appRouter.go('/staff');
            } else {
              appRouter.go('/home');
            }
          }
        },
        child: MaterialApp.router(
          title: 'AIT Airlines',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFE94560),
            scaffoldBackgroundColor: const Color(0xFF1A1A2E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE94560),
              secondary: Color(0xFF0F3460),
              surface: Color(0xFF16213E),
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              elevation: 0,
              centerTitle: true,
            ),
          ),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
