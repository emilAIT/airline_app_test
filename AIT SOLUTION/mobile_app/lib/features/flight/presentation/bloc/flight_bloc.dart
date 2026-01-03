import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/flight_repository.dart';
import '../../domain/entities/seat_map.dart';
import 'flight_event.dart';
import 'flight_state.dart';

@injectable
class FlightBloc extends Bloc<FlightEvent, FlightState> {
  final FlightRepository _repository;

  FlightBloc(this._repository) : super(FlightInitial()) {
    on<FetchFlights>(_onFetchFlights);
    on<FetchAirports>(_onFetchAirports);
    on<CreateAirportRequested>(_onSafeCreateAirport);
    on<CreateFlightRequested>(_onCreateFlightRequested);
    on<UpdateFlightStatusRequested>(_onUpdateFlightStatus);
    on<FlightSeatMapRequested>(_onFlightSeatMapRequested);
    on<UpdateFlightGatesRequested>(_onUpdateFlightGates);
  }

  Future<void> _onFetchFlights(
    FetchFlights event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.getFlights(
      departure: event.departure,
      arrival: event.arrival,
      date: event.date,
      passengersCount: event.passengersCount,
    );
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (flights) => emit(FlightsLoaded(flights)),
    );
  }

  Future<void> _onFetchAirports(
    FetchAirports event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.getAirports();
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (airports) => emit(AirportsLoaded(airports)),
    );
  }

  Future<void> _onSafeCreateAirport(
    CreateAirportRequested event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.createAirport(event.airportData);
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (airport) => emit(AirportCreated(airport)),
    );
  }

  Future<void> _onCreateFlightRequested(
    CreateFlightRequested event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.createFlight(event.flightData);
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (flight) => emit(FlightCreated(flight)),
    );
  }

  Future<void> _onUpdateFlightStatus(
    UpdateFlightStatusRequested event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.updateFlightStatus(event.flightId, event.status);
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (flight) => emit(FlightUpdated(flight)),
    );
  }

  Future<void> _onUpdateFlightGates(
    UpdateFlightGatesRequested event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.updateGates(event.flightId, event.gateDeparture, event.gateArrival);
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (flight) => emit(FlightUpdated(flight)),
    );
  }

  Future<void> _onFlightSeatMapRequested(
    FlightSeatMapRequested event,
    Emitter<FlightState> emit,
  ) async {
    emit(FlightLoading());
    final result = await _repository.getSeatMap(event.flightId);
    result.fold(
      (failure) => emit(FlightError(failure.message)),
      (seats) => emit(FlightSeatMapSuccess(SeatMap(seats: seats))),
    );
  }
}
