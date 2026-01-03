// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../services/airplane_service.dart';
import '../services/airport_service.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/checkin_service.dart';
import '../services/flight_service.dart';
import '../services/payment_service.dart';
import '../services/seat_hold_service.dart';
import '../services/ticket_service.dart';
import '../services/user_service.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => ApiService());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => FlightService());
  locator.registerLazySingleton(() => BookingService());
  locator.registerLazySingleton(() => PaymentService());
  locator.registerLazySingleton(() => AirplaneService());
  locator.registerLazySingleton(() => AirportService());
  locator.registerLazySingleton(() => UserService());
  locator.registerLazySingleton(() => AnnouncementService());
  locator.registerLazySingleton(() => TicketService());
  locator.registerLazySingleton(() => CheckInService());
  locator.registerLazySingleton(() => SeatHoldService());
}
