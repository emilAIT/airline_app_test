// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i18;
import 'package:flutter/material.dart';
import 'package:flutter_airline_app/models/flight_model.dart' as _i19;
import 'package:flutter_airline_app/ui/views/announcements/announcements_view.dart'
    as _i17;
import 'package:flutter_airline_app/ui/views/booking/booking_view.dart' as _i7;
import 'package:flutter_airline_app/ui/views/booking_details/booking_details_view.dart'
    as _i11;
import 'package:flutter_airline_app/ui/views/create_airport/create_airport_view.dart'
    as _i15;
import 'package:flutter_airline_app/ui/views/flight_details/flight_details_view.dart'
    as _i13;
import 'package:flutter_airline_app/ui/views/flight_results/flight_results_view.dart'
    as _i12;
import 'package:flutter_airline_app/ui/views/flight_search/flight_search_view.dart'
    as _i6;
import 'package:flutter_airline_app/ui/views/home/home_view.dart' as _i2;
import 'package:flutter_airline_app/ui/views/login/login_view.dart' as _i4;
import 'package:flutter_airline_app/ui/views/manage_trips/manage_trips_view.dart'
    as _i14;
import 'package:flutter_airline_app/ui/views/my_bookings/my_bookings_view.dart'
    as _i8;
import 'package:flutter_airline_app/ui/views/payment/payment_view.dart' as _i9;
import 'package:flutter_airline_app/ui/views/profile/profile_view.dart' as _i10;
import 'package:flutter_airline_app/ui/views/register/register_view.dart'
    as _i5;
import 'package:flutter_airline_app/ui/views/startup/startup_view.dart' as _i3;
import 'package:flutter_airline_app/ui/views/update_airport/update_airport_view.dart'
    as _i16;
import 'package:flutter_airline_app/ui/views/update_airport/update_airport_viewmodel.dart'
    as _i20;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i21;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const registerView = '/register-view';

  static const flightSearchView = '/flight-search-view';

  static const bookingView = '/booking-view';

  static const myBookingsView = '/my-bookings-view';

  static const paymentView = '/payment-view';

  static const profileView = '/profile-view';

  static const bookingDetailsView = '/booking-details-view';

  static const flightResultsView = '/flight-results-view';

  static const flightDetailsView = '/flight-details-view';

  static const manageTripsView = '/manage-trips-view';

  static const createAirportView = '/create-airport-view';

  static const updateAirportView = '/update-airport-view';

  static const announcementsView = '/announcements-view';

  static const all = <String>{
    homeView,
    startupView,
    loginView,
    registerView,
    flightSearchView,
    bookingView,
    myBookingsView,
    paymentView,
    profileView,
    bookingDetailsView,
    flightResultsView,
    flightDetailsView,
    manageTripsView,
    createAirportView,
    updateAirportView,
    announcementsView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i4.LoginView,
    ),
    _i1.RouteDef(
      Routes.registerView,
      page: _i5.RegisterView,
    ),
    _i1.RouteDef(
      Routes.flightSearchView,
      page: _i6.FlightSearchView,
    ),
    _i1.RouteDef(
      Routes.bookingView,
      page: _i7.BookingView,
    ),
    _i1.RouteDef(
      Routes.myBookingsView,
      page: _i8.MyBookingsView,
    ),
    _i1.RouteDef(
      Routes.paymentView,
      page: _i9.PaymentView,
    ),
    _i1.RouteDef(
      Routes.profileView,
      page: _i10.ProfileView,
    ),
    _i1.RouteDef(
      Routes.bookingDetailsView,
      page: _i11.BookingDetailsView,
    ),
    _i1.RouteDef(
      Routes.flightResultsView,
      page: _i12.FlightResultsView,
    ),
    _i1.RouteDef(
      Routes.flightDetailsView,
      page: _i13.FlightDetailsView,
    ),
    _i1.RouteDef(
      Routes.manageTripsView,
      page: _i14.ManageTripsView,
    ),
    _i1.RouteDef(
      Routes.createAirportView,
      page: _i15.CreateAirportView,
    ),
    _i1.RouteDef(
      Routes.updateAirportView,
      page: _i16.UpdateAirportView,
    ),
    _i1.RouteDef(
      Routes.announcementsView,
      page: _i17.AnnouncementsView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i2.HomeView(),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i3.StartupView(),
        settings: data,
      );
    },
    _i4.LoginView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i4.LoginView(),
        settings: data,
      );
    },
    _i5.RegisterView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i5.RegisterView(),
        settings: data,
      );
    },
    _i6.FlightSearchView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i6.FlightSearchView(),
        settings: data,
      );
    },
    _i7.BookingView: (data) {
      final args = data.getArgs<BookingViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i7.BookingView(key: args.key, flightId: args.flightId),
        settings: data,
      );
    },
    _i8.MyBookingsView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i8.MyBookingsView(),
        settings: data,
      );
    },
    _i9.PaymentView: (data) {
      final args = data.getArgs<PaymentViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i9.PaymentView(key: args.key, bookingId: args.bookingId),
        settings: data,
      );
    },
    _i10.ProfileView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i10.ProfileView(),
        settings: data,
      );
    },
    _i11.BookingDetailsView: (data) {
      final args = data.getArgs<BookingDetailsViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i11.BookingDetailsView(key: args.key, bookingId: args.bookingId),
        settings: data,
      );
    },
    _i12.FlightResultsView: (data) {
      final args = data.getArgs<FlightResultsViewArguments>(
        orElse: () => const FlightResultsViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i12.FlightResultsView(
            key: args.key,
            initialFlights: args.initialFlights,
            searchParams: args.searchParams),
        settings: data,
      );
    },
    _i13.FlightDetailsView: (data) {
      final args = data.getArgs<FlightDetailsViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i13.FlightDetailsView(key: args.key, flightId: args.flightId),
        settings: data,
      );
    },
    _i14.ManageTripsView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i14.ManageTripsView(),
        settings: data,
      );
    },
    _i15.CreateAirportView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i15.CreateAirportView(),
        settings: data,
      );
    },
    _i16.UpdateAirportView: (data) {
      final args = data.getArgs<UpdateAirportViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i16.UpdateAirportView(key: args.key, args: args.args),
        settings: data,
      );
    },
    _i17.AnnouncementsView: (data) {
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => const _i17.AnnouncementsView(),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class BookingViewArguments {
  const BookingViewArguments({
    this.key,
    required this.flightId,
  });

  final _i18.Key? key;

  final String flightId;

  @override
  String toString() {
    return '{"key": "$key", "flightId": "$flightId"}';
  }

  @override
  bool operator ==(covariant BookingViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.flightId == flightId;
  }

  @override
  int get hashCode {
    return key.hashCode ^ flightId.hashCode;
  }
}

class PaymentViewArguments {
  const PaymentViewArguments({
    this.key,
    required this.bookingId,
  });

  final _i18.Key? key;

  final String bookingId;

  @override
  String toString() {
    return '{"key": "$key", "bookingId": "$bookingId"}';
  }

  @override
  bool operator ==(covariant PaymentViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    return key.hashCode ^ bookingId.hashCode;
  }
}

class BookingDetailsViewArguments {
  const BookingDetailsViewArguments({
    this.key,
    required this.bookingId,
  });

  final _i18.Key? key;

  final String bookingId;

  @override
  String toString() {
    return '{"key": "$key", "bookingId": "$bookingId"}';
  }

  @override
  bool operator ==(covariant BookingDetailsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    return key.hashCode ^ bookingId.hashCode;
  }
}

class FlightResultsViewArguments {
  const FlightResultsViewArguments({
    this.key,
    this.initialFlights,
    this.searchParams,
  });

  final _i18.Key? key;

  final List<_i19.FlightSearchResult>? initialFlights;

  final _i19.FlightSearchParams? searchParams;

  @override
  String toString() {
    return '{"key": "$key", "initialFlights": "$initialFlights", "searchParams": "$searchParams"}';
  }

  @override
  bool operator ==(covariant FlightResultsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.initialFlights == initialFlights &&
        other.searchParams == searchParams;
  }

  @override
  int get hashCode {
    return key.hashCode ^ initialFlights.hashCode ^ searchParams.hashCode;
  }
}

class FlightDetailsViewArguments {
  const FlightDetailsViewArguments({
    this.key,
    required this.flightId,
  });

  final _i18.Key? key;

  final String flightId;

  @override
  String toString() {
    return '{"key": "$key", "flightId": "$flightId"}';
  }

  @override
  bool operator ==(covariant FlightDetailsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.flightId == flightId;
  }

  @override
  int get hashCode {
    return key.hashCode ^ flightId.hashCode;
  }
}

class UpdateAirportViewArguments {
  const UpdateAirportViewArguments({
    this.key,
    required this.args,
  });

  final _i18.Key? key;

  final _i20.UpdateAirportViewArguments args;

  @override
  String toString() {
    return '{"key": "$key", "args": "$args"}';
  }

  @override
  bool operator ==(covariant UpdateAirportViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.args == args;
  }

  @override
  int get hashCode {
    return key.hashCode ^ args.hashCode;
  }
}

extension NavigatorStateExtension on _i21.NavigationService {
  Future<dynamic> navigateToHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.loginView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToRegisterView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.registerView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFlightSearchView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.flightSearchView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToBookingView({
    _i18.Key? key,
    required String flightId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.bookingView,
        arguments: BookingViewArguments(key: key, flightId: flightId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToMyBookingsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.myBookingsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPaymentView({
    _i18.Key? key,
    required String bookingId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.paymentView,
        arguments: PaymentViewArguments(key: key, bookingId: bookingId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToProfileView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.profileView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToBookingDetailsView({
    _i18.Key? key,
    required String bookingId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.bookingDetailsView,
        arguments: BookingDetailsViewArguments(key: key, bookingId: bookingId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFlightResultsView({
    _i18.Key? key,
    List<_i19.FlightSearchResult>? initialFlights,
    _i19.FlightSearchParams? searchParams,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.flightResultsView,
        arguments: FlightResultsViewArguments(
            key: key,
            initialFlights: initialFlights,
            searchParams: searchParams),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFlightDetailsView({
    _i18.Key? key,
    required String flightId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.flightDetailsView,
        arguments: FlightDetailsViewArguments(key: key, flightId: flightId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToManageTripsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.manageTripsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCreateAirportView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.createAirportView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToUpdateAirportView({
    _i18.Key? key,
    required _i20.UpdateAirportViewArguments args,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.updateAirportView,
        arguments: UpdateAirportViewArguments(key: key, args: args),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToAnnouncementsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.announcementsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.loginView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithRegisterView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.registerView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFlightSearchView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.flightSearchView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithBookingView({
    _i18.Key? key,
    required String flightId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.bookingView,
        arguments: BookingViewArguments(key: key, flightId: flightId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithMyBookingsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.myBookingsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPaymentView({
    _i18.Key? key,
    required String bookingId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.paymentView,
        arguments: PaymentViewArguments(key: key, bookingId: bookingId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithProfileView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.profileView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithBookingDetailsView({
    _i18.Key? key,
    required String bookingId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.bookingDetailsView,
        arguments: BookingDetailsViewArguments(key: key, bookingId: bookingId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFlightResultsView({
    _i18.Key? key,
    List<_i19.FlightSearchResult>? initialFlights,
    _i19.FlightSearchParams? searchParams,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.flightResultsView,
        arguments: FlightResultsViewArguments(
            key: key,
            initialFlights: initialFlights,
            searchParams: searchParams),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFlightDetailsView({
    _i18.Key? key,
    required String flightId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.flightDetailsView,
        arguments: FlightDetailsViewArguments(key: key, flightId: flightId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithManageTripsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.manageTripsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCreateAirportView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.createAirportView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithUpdateAirportView({
    _i18.Key? key,
    required _i20.UpdateAirportViewArguments args,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.updateAirportView,
        arguments: UpdateAirportViewArguments(key: key, args: args),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithAnnouncementsView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.announcementsView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
