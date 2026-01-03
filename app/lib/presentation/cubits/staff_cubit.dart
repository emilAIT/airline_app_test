import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/staff_repository.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/booking.dart';

abstract class StaffState extends Equatable {
  const StaffState();
  
  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffDataLoaded extends StaffState {
  final List<Flight> flights;
  final List<Booking> bookings;
  const StaffDataLoaded({required this.flights, required this.bookings});
  
  @override
  List<Object?> get props => [flights, bookings];
}

class StaffError extends StaffState {
  final String message;
  const StaffError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _staffRepository;

  StaffCubit(this._staffRepository) : super(StaffInitial());

  Future<void> loadDashboardData() async {
    emit(StaffLoading());
    try {
      final flights = await _staffRepository.getAllFlights();
      final bookings = await _staffRepository.getAllBookings();
      emit(StaffDataLoaded(flights: flights, bookings: bookings));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> updateFlightStatus(int flightId, String status) async {
    try {
      await _staffRepository.updateFlight(flightId, {'status': status});
      await loadDashboardData();
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }
}
