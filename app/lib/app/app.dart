import 'package:flutter_airline_app/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:flutter_airline_app/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:flutter_airline_app/ui/views/home/home_view.dart';
import 'package:flutter_airline_app/ui/views/startup/startup_view.dart';
import 'package:flutter_airline_app/ui/views/login/login_view.dart';
import 'package:flutter_airline_app/ui/views/register/register_view.dart';
import 'package:flutter_airline_app/ui/views/flight_search/flight_search_view.dart';
import 'package:flutter_airline_app/ui/views/booking/booking_view.dart';
import 'package:flutter_airline_app/ui/views/my_bookings/my_bookings_view.dart';
import 'package:flutter_airline_app/ui/views/payment/payment_view.dart';
import 'package:flutter_airline_app/ui/views/profile/profile_view.dart';
import 'package:flutter_airline_app/ui/views/booking_details/booking_details_view.dart';
import 'package:flutter_airline_app/ui/views/flight_results/flight_results_view.dart';
import 'package:flutter_airline_app/ui/views/flight_details/flight_details_view.dart';
import 'package:flutter_airline_app/ui/views/manage_trips/manage_trips_view.dart';
import 'package:flutter_airline_app/ui/views/create_airport/create_airport_view.dart';
import 'package:flutter_airline_app/ui/views/update_airport/update_airport_view.dart';
import 'package:flutter_airline_app/ui/views/announcements/announcements_view.dart';
import 'package:flutter_airline_app/services/api_service.dart';
import 'package:flutter_airline_app/services/auth_service.dart';
import 'package:flutter_airline_app/services/flight_service.dart';
import 'package:flutter_airline_app/services/booking_service.dart';
import 'package:flutter_airline_app/services/payment_service.dart';
import 'package:flutter_airline_app/services/airplane_service.dart';
import 'package:flutter_airline_app/services/airport_service.dart';
import 'package:flutter_airline_app/services/user_service.dart';
import 'package:flutter_airline_app/services/announcement_service.dart';
import 'package:flutter_airline_app/services/ticket_service.dart';
import 'package:flutter_airline_app/services/checkin_service.dart';
import 'package:flutter_airline_app/services/seat_hold_service.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: RegisterView),
    MaterialRoute(page: FlightSearchView),
    MaterialRoute(page: BookingView),
    MaterialRoute(page: MyBookingsView),
    MaterialRoute(page: PaymentView),
    MaterialRoute(page: ProfileView),
    MaterialRoute(page: BookingDetailsView),
    MaterialRoute(page: FlightResultsView),
    MaterialRoute(page: FlightDetailsView),
    MaterialRoute(page: ManageTripsView),
    MaterialRoute(page: CreateAirportView),
    MaterialRoute(page: UpdateAirportView),
    MaterialRoute(page: AnnouncementsView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: ApiService),
    LazySingleton(classType: AuthService),
    LazySingleton(classType: FlightService),
    LazySingleton(classType: BookingService),
    LazySingleton(classType: PaymentService),
    LazySingleton(classType: AirplaneService),
    LazySingleton(classType: AirportService),
    LazySingleton(classType: UserService),
    LazySingleton(classType: AnnouncementService),
    LazySingleton(classType: TicketService),
    LazySingleton(classType: CheckInService),
    LazySingleton(classType: SeatHoldService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
