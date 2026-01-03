import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:ait_airlines/core/usecases/usecase.dart';
import 'package:ait_airlines/features/airplane/presentation/bloc/airplane_event.dart';
import 'package:ait_airlines/features/airplane/presentation/bloc/airplane_state.dart';
import 'package:ait_airlines/features/airplane/domain/usecases/add_airplane_usecase.dart';
import 'package:ait_airlines/features/airplane/domain/usecases/get_airplanes_usecase.dart';
import 'package:ait_airlines/features/airplane/domain/usecases/delete_airplane_usecase.dart';

@injectable
class AirplaneBloc extends Bloc<AirplaneEvent, AirplaneState> {
  final GetAirplanesUseCase _getAirplanesUseCase;
  final AddAirplaneUseCase _addAirplaneUseCase;
  final DeleteAirplaneUseCase _deleteAirplaneUseCase;

  AirplaneBloc(
    this._getAirplanesUseCase,
    this._addAirplaneUseCase,
    this._deleteAirplaneUseCase,
  ) : super(AirplaneInitial()) {
    on<FetchAirplanes>(_onFetchAirplanes);
    on<AddAirplane>(_onAddAirplane);
    on<DeleteAirplane>(_onDeleteAirplane);
  }

  Future<void> _onFetchAirplanes(
    FetchAirplanes event,
    Emitter<AirplaneState> emit,
  ) async {
    emit(AirplaneLoading());
    final result = await _getAirplanesUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AirplaneError(failure.toString())),
      (airplanes) => emit(AirplaneLoaded(airplanes)),
    );
  }

  Future<void> _onAddAirplane(
    AddAirplane event,
    Emitter<AirplaneState> emit,
  ) async {
    emit(AirplaneLoading());
    final result = await _addAirplaneUseCase(AddAirplaneParams(event.airplane));
    
    result.fold(
      (failure) => emit(AirplaneError(failure.toString())),
      (airplane) {
        emit(const AirplaneOperationSuccess('Airplane added successfully'));
        add(FetchAirplanes()); // Refresh list
      },
    );
  }

  Future<void> _onDeleteAirplane(
    DeleteAirplane event,
    Emitter<AirplaneState> emit,
  ) async {
    emit(AirplaneLoading());
    final result = await _deleteAirplaneUseCase(event.id);
    
    result.fold(
      (failure) => emit(AirplaneError(failure.toString())),
      (_) {
        emit(const AirplaneOperationSuccess('Airplane deleted successfully'));
        add(FetchAirplanes()); // Refresh list
      },
    );
  }
}
