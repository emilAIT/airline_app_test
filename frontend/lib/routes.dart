import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/passenger/profile_screen.dart';
import 'screens/passenger/my_trips_screen.dart';
import 'screens/passenger/announcements_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/staff/manage_flights_screen.dart';
import 'screens/staff/manage_announcements_screen.dart';
import 'screens/passenger/all_flights_screen.dart';
import 'screens/passenger/airports_screen.dart';

final routes = <String, WidgetBuilder>{
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/profile_update': (_) => const PassengerProfileScreen(),
  '/': (_) => const HomePage(),
  '/my_trips': (_) => const MyTripsScreen(),
  '/announcements': (_) => const AnnouncementsScreen(),
  '/staff': (_) => const StaffDashboard(),
  '/staff/flights': (_) => const ManageFlightsScreen(),
  '/staff/announcements': (_) => const ManageAnnouncementsScreen(),
  '/all_flights': (_) => const AllFlightsScreen(),
  '/airports': (_) => const AirportsScreen(),
};
