// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/admin/data/repositories/admin_repository_impl.dart'
    as _i335;
import '../../features/admin/domain/repositories/admin_repository.dart'
    as _i583;
import '../../features/airplane/data/repositories/airplane_repository_impl.dart'
    as _i207;
import '../../features/airplane/domain/repositories/airplane_repository.dart'
    as _i405;
import '../../features/airplane/domain/usecases/add_airplane_usecase.dart'
    as _i293;
import '../../features/airplane/domain/usecases/delete_airplane_usecase.dart'
    as _i17;
import '../../features/airplane/domain/usecases/get_airplanes_usecase.dart'
    as _i635;
import '../../features/airplane/presentation/bloc/airplane_bloc.dart' as _i504;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/booking/data/repositories/booking_repository_impl.dart'
    as _i265;
import '../../features/booking/domain/repositories/booking_repository.dart'
    as _i912;
import '../../features/booking/domain/usecases/booking_usecases.dart' as _i1015;
import '../../features/booking/presentation/bloc/booking_bloc.dart' as _i802;
import '../../features/flight/data/repositories/flight_repository_impl.dart'
    as _i409;
import '../../features/flight/domain/repositories/flight_repository.dart'
    as _i262;
import '../../features/flight/domain/usecases/create_airport_usecase.dart'
    as _i245;
import '../../features/flight/domain/usecases/create_flight_usecase.dart'
    as _i426;
import '../../features/flight/domain/usecases/get_airports_usecase.dart'
    as _i104;
import '../../features/flight/domain/usecases/get_flights_usecase.dart'
    as _i578;
import '../../features/flight/domain/usecases/get_seat_map_usecase.dart'
    as _i55;
import '../../features/flight/domain/usecases/update_flight_status_usecase.dart'
    as _i626;
import '../../features/flight/presentation/bloc/flight_bloc.dart' as _i873;
import '../../features/notifications/presentation/bloc/notification_bloc.dart'
    as _i876;
import '../network/api_client.dart' as _i557;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i557.ApiClient>(() => _i557.ApiClient());
    gh.factory<_i405.AirplaneRepository>(
        () => _i207.AirplaneRepositoryImpl(gh<_i557.ApiClient>()));
    gh.lazySingleton<_i583.AdminRepository>(
        () => _i335.AdminRepositoryImpl(gh<_i557.ApiClient>()));
    gh.factory<_i876.NotificationBloc>(
        () => _i876.NotificationBloc(gh<_i557.ApiClient>()));
    gh.factory<_i262.FlightRepository>(
        () => _i409.FlightRepositoryImpl(gh<_i557.ApiClient>()));
    gh.lazySingleton<_i912.BookingRepository>(
        () => _i265.BookingRepositoryImpl(gh<_i557.ApiClient>()));
    gh.lazySingleton<_i1015.CreateBookingUseCase>(
        () => _i1015.CreateBookingUseCase(gh<_i912.BookingRepository>()));
    gh.lazySingleton<_i1015.GetMyBookingsUseCase>(
        () => _i1015.GetMyBookingsUseCase(gh<_i912.BookingRepository>()));
    gh.lazySingleton<_i1015.ProcessPaymentUseCase>(
        () => _i1015.ProcessPaymentUseCase(gh<_i912.BookingRepository>()));
    gh.lazySingleton<_i1015.CheckInUseCase>(
        () => _i1015.CheckInUseCase(gh<_i912.BookingRepository>()));
    gh.lazySingleton<_i787.AuthRepository>(
        () => _i153.AuthRepositoryImpl(gh<_i557.ApiClient>()));
    gh.factory<_i293.AddAirplaneUseCase>(
        () => _i293.AddAirplaneUseCase(gh<_i405.AirplaneRepository>()));
    gh.factory<_i17.DeleteAirplaneUseCase>(
        () => _i17.DeleteAirplaneUseCase(gh<_i405.AirplaneRepository>()));
    gh.factory<_i635.GetAirplanesUseCase>(
        () => _i635.GetAirplanesUseCase(gh<_i405.AirplaneRepository>()));
    gh.factory<_i245.CreateAirportUseCase>(
        () => _i245.CreateAirportUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i426.CreateFlightUseCase>(
        () => _i426.CreateFlightUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i104.GetAirportsUseCase>(
        () => _i104.GetAirportsUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i578.GetFlightsUseCase>(
        () => _i578.GetFlightsUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i55.GetSeatMapUseCase>(
        () => _i55.GetSeatMapUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i626.UpdateFlightStatusUseCase>(
        () => _i626.UpdateFlightStatusUseCase(gh<_i262.FlightRepository>()));
    gh.factory<_i873.FlightBloc>(
        () => _i873.FlightBloc(gh<_i262.FlightRepository>()));
    gh.factory<_i802.BookingBloc>(
        () => _i802.BookingBloc(gh<_i912.BookingRepository>()));
    gh.factory<_i797.AuthBloc>(
        () => _i797.AuthBloc(gh<_i787.AuthRepository>()));
    gh.factory<_i504.AirplaneBloc>(() => _i504.AirplaneBloc(
          gh<_i635.GetAirplanesUseCase>(),
          gh<_i293.AddAirplaneUseCase>(),
          gh<_i17.DeleteAirplaneUseCase>(),
        ));
    return this;
  }
}
