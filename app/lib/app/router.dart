import 'package:flutter/material.dart';
import '../features/auth/splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/profile_page.dart';
import '../features/auth/profile_edit_page.dart';
import '../features/home/passenger_home_page.dart';
import '../features/home/staff_home_page.dart';
import '../features/flights/flight_search_page.dart';
import '../features/flights/flight_list_page.dart';
import '../features/flights/flight_details_page.dart';
import '../features/flights/seat_map_page.dart';
import '../features/booking/passenger_info_page.dart';
import '../features/booking/seat_selection_page.dart';
import '../features/booking/booking_review_page.dart';
import '../features/booking/payment_page.dart';
import '../features/booking/booking_success_page.dart';
import '../features/trips/my_trips_page.dart';
import '../features/trips/trip_details_page.dart';
import '../features/checkin/checkin_page.dart';
import '../features/checkin/boarding_pass_page.dart';
import '../features/announcements/announcements_page.dart';
import '../features/staff_airplanes/staff_airplanes_page.dart';
import '../features/staff_airplanes/create_airplane_page.dart';
import '../features/staff_airplanes/edit_airplane_page.dart';
import '../features/staff_flights/staff_flights_page.dart';
import '../features/staff_flights/create_flight_page.dart';
import '../features/staff_flights/edit_flight_page.dart';
import '../features/staff_bookings/staff_bookings_page.dart';
import '../features/staff_bookings/booking_details_staff_page.dart';
import '../features/staff_announcements/staff_announcements_page.dart';
import '../features/staff_announcements/create_announcement_page.dart';
import '../features/staff_announcements/edit_announcement_page.dart';

class AppRouter {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  // Home routes
  static const String passengerHome = '/passenger-home';
  static const String staffHome = '/staff-home';

  // Flights routes
  static const String flightSearch = '/flight-search';
  static const String flightList = '/flight-list';
  static const String flightDetails = '/flight-details';
  static const String seatMap = '/seat-map';

  // Booking routes
  static const String passengerInfo = '/passenger-info';
  static const String seatSelection = '/seat-selection';
  static const String bookingReview = '/booking-review';
  static const String payment = '/payment';
  static const String bookingSuccess = '/booking-success';

  // Trips routes
  static const String myTrips = '/my-trips';
  static const String tripDetails = '/trip-details';

  // Check-in routes
  static const String checkin = '/checkin';
  static const String boardingPass = '/boarding-pass';

  // Announcements routes
  static const String announcements = '/announcements';

  // Staff routes
  static const String staffAirplanes = '/staff/airplanes';
  static const String staffAirplaneCreate = '/staff/airplanes/create';
  static const String staffAirplaneDetails = '/staff/airplanes/details';
  static const String staffFlights = '/staff/flights';
  static const String staffFlightCreate = '/staff/flights/create';
  static const String staffFlightEdit = '/staff/flights/edit';
  static const String staffBookings = '/staff/bookings';
  static const String staffBookingSearch = '/staff/bookings/search';
  static const String staffSeatReassign = '/staff/bookings/reassign';
  static const String staffAnnouncements = '/staff/announcements';
  static const String staffAnnouncementCreate = '/staff/announcements/create';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditPage());

      // Home
      case passengerHome:
        return MaterialPageRoute(builder: (_) => const PassengerHomePage());
      case staffHome:
        return MaterialPageRoute(builder: (_) => const StaffHomePage());

      // Flights
      case flightSearch:
        return MaterialPageRoute(builder: (_) => const FlightSearchPage());
      case flightList:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FlightListPage(searchParams: args ?? {}),
        );
      case flightDetails:
        final flightId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => FlightDetailsPage(flightId: flightId),
        );
      case seatMap:
        final flightId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => SeatMapPage(flightId: flightId),
        );

      // Booking
      case passengerInfo:
        final flightId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PassengerInfoPage(flightId: flightId),
        );
      case seatSelection:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SeatSelectionPage(
            flightId: args['flightId'],
            passengers: args['passengers'],
          ),
        );
      case bookingReview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BookingReviewPage(
            flightId: args['flightId'],
            passengers: args['passengers'],
            selectedSeats: args['selectedSeats'],
          ),
        );
      case payment:
        final bookingPnr = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PaymentPage(bookingPnr: bookingPnr),
        );
      case bookingSuccess:
        final bookingId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BookingSuccessPage(bookingId: bookingId),
        );

      // Trips
      case myTrips:
        return MaterialPageRoute(builder: (_) => const MyTripsPage());
      case tripDetails:
        final bookingId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => TripDetailsPage(bookingId: bookingId),
        );

      // Check-in
      case checkin:
        final ticketId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => CheckinPage(ticketId: ticketId),
        );
      case boardingPass:
        final ticketId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BoardingPassPage(ticketId: ticketId),
        );

      // Announcements
      case announcements:
        return MaterialPageRoute(builder: (_) => const AnnouncementsPage());

      // Staff - Airplanes
      case staffAirplanes:
        return MaterialPageRoute(builder: (_) => const StaffAirplanesPage());
      case staffAirplaneCreate:
        return MaterialPageRoute(builder: (_) => const CreateAirplanePage());
      case staffAirplaneDetails:
        final airplaneId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditAirplanePage(airplaneId: airplaneId),
        );

      // Staff - Flights
      case staffFlights:
        return MaterialPageRoute(builder: (_) => const StaffFlightsPage());
      case staffFlightCreate:
        return MaterialPageRoute(builder: (_) => const CreateFlightPage());
      case staffFlightEdit:
        final flightId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditFlightPage(flightId: flightId),
        );

      // Staff - Bookings
      case staffBookings:
        return MaterialPageRoute(builder: (_) => const StaffBookingsPage());
      case staffBookingSearch:
        final pnr = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookingDetailsStaffPage(pnr: pnr),
        );
      case staffSeatReassign:
        final pnr = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookingDetailsStaffPage(pnr: pnr),
        );

      // Staff - Announcements
      case staffAnnouncements:
        return MaterialPageRoute(
          builder: (_) => const StaffAnnouncementsPage(),
        );
      case staffAnnouncementCreate:
        return MaterialPageRoute(builder: (_) => const CreateAnnouncementPage());
      case '/staff/announcements/edit':
        final announcementId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditAnnouncementPage(announcementId: announcementId),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

