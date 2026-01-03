import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/staff_management_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/airplane/presentation/pages/airplane_list_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/booking/presentation/pages/my_bookings_page.dart';
import '../../features/booking/presentation/pages/payment_page.dart';
import '../../features/flight/presentation/pages/seat_selection_page.dart';
import '../../features/flight/presentation/pages/search_flights_page.dart';
import '../../features/flight/domain/entities/flight.dart';
import '../../features/booking/domain/entities/booking.dart';
import '../../features/flight/presentation/pages/manage_flights_page.dart';
import '../../features/airplane/presentation/pages/add_airplane_page.dart';
import '../../features/flight/presentation/pages/add_flight_page.dart';
import '../../features/flight/presentation/pages/add_airport_page.dart';
import '../../features/flight/presentation/pages/airport_list_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/staff/presentation/pages/staff_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/booking/presentation/pages/check_in_page.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/flight/presentation/pages/flight_passengers_page.dart';
import '../../features/flight/presentation/pages/create_announcement_page.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: '/home',  // Изменено с /login на /home
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
      routes: [
        GoRoute(
          path: 'staff',
          builder: (context, state) => const StaffManagementPage(),
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const AdminUsersPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/airplanes',
      builder: (context, state) => const AirplaneListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddAirplanePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/flights',
      builder: (context, state) => const ManageFlightsPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddFlightPage(),
        ),
        GoRoute(
          path: ':id/seats',
          builder: (context, state) {
            // Поддержка передачи как Flight напрямую, так и Map с flight и passengersCount
            final extra = state.extra;
            Flight flight;
            int passengersCount = 1;

            if (extra is Map<String, dynamic>) {
              flight = extra['flight'] as Flight;
              passengersCount = extra['passengersCount'] as int? ?? 1;
            } else {
              flight = extra as Flight;
            }

            return SeatSelectionPage(
                flight: flight, passengersCount: passengersCount);
          },
        ),
        GoRoute(
          path: ':id/passengers',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return FlightPassengersPage(flightId: id);
          },
        ),
        GoRoute(
          path: ':id/announcement',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CreateAnnouncementPage(flightId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/airports',
      builder: (context, state) => const AirportListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddAirportPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffDashboardPage(),
    ),
    GoRoute(
      path: '/announcements/create',
      builder: (context, state) => const CreateAnnouncementPage(),
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const MyBookingsPage(),
      routes: [
        GoRoute(
          path: ':id/checkin',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CheckInPage(bookingId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/booking-history',
      builder: (context, state) => const BookingHistoryPage(),
    ),
    GoRoute(
      path: '/payments/checkout',
      builder: (context, state) {
        final booking = state.extra as Booking;
        return PaymentPage(booking: booking);
      },
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text("Support Center (Coming Soon)")),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchFlightsPage(
          initialDeparture: extra?['departure'] as String?,
          initialArrival: extra?['arrival'] as String?,
          initialDate: extra?['date'] as DateTime?,
          initialPax: extra?['pax'] as int?,
        );
      },
    ),
  ],
);
