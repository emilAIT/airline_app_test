import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/flights_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/announcements_provider.dart';
import 'providers/airports_provider.dart';
import 'routes.dart';
import 'core/theme/app_theme.dart';

class AirlineApp extends StatelessWidget {
  const AirlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FlightsProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementsProvider()),
        ChangeNotifierProvider(create: (_) => AirportsProvider()),
      ],
      child: MaterialApp(
        title: 'Airline App',
        theme: AppTheme.light(),
        routes: routes,
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}