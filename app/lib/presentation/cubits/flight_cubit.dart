import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/flight_repository.dart';
import '../../domain/entities/flight.dart';

abstract class FlightState extends Equatable {
  const FlightState();
  
  @override
  List<Object?> get props => [];
}

class FlightInitial extends FlightState {}

class FlightLoading extends FlightState {}

class FlightSearchResults extends FlightState {
  final List<Flight> flights;
  const FlightSearchResults(this.flights);
  
  @override
  List<Object?> get props => [flights];
}

class FlightDetailLoaded extends FlightState {
  final Map<String, dynamic> detail;
  const FlightDetailLoaded(this.detail);
  
  @override
  List<Object?> get props => [detail];
}

class FlightError extends FlightState {
  final String message;
  const FlightError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class FlightCubit extends Cubit<FlightState> {
  final FlightRepository _flightRepository;

  FlightCubit(this._flightRepository) : super(FlightInitial());

  Future<void> searchFlights({int? originId, int? destinationId, DateTime? date}) async {
    emit(FlightLoading());
    try {
      // Ensure all required parameters are provided
      if (originId == null || destinationId == null || date == null) {
        throw Exception('Origin, destination, and date are required');
      }
      
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      final flights = await _flightRepository.searchFlights(
        originId,
        destinationId,
        dateStr,
      );
      emit(FlightSearchResults(flights));
    } catch (e) {
      emit(FlightError(e.toString()));
    }
  }

  Future<void> loadAllFlights() async {
    emit(FlightLoading());
    try {
      final flights = await _flightRepository.listFlights();
      emit(FlightSearchResults(flights));
    } catch (e) {
      emit(FlightError(e.toString()));
    }
  }

  Future<void> getDetails(int flightId) async {
    emit(FlightLoading());
    try {
      final detail = await _flightRepository.getFlightDetails(flightId);
      emit(FlightDetailLoaded(detail));
    } catch (e) {
      emit(FlightError(e.toString()));
    }
  }
}
