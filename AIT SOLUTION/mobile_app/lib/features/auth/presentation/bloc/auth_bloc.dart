import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Note: We don't emit Loading here to avoid flickering if we are already logged in
    // But let's keep it consistent for now.
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.login(event.email, event.password);
    
    await result.fold(
      (failure) async {
        emit(AuthFailureState(failure.message));
      },
      (token) async {
         // Token is already set in repository/ApiClient by this point
         final userResult = await _authRepository.getCurrentUser();
         await userResult.fold(
           (failure) async => emit(AuthFailureState("Login success but failed to fetch user data: ${failure.message}")),
           (user) async => emit(AuthAuthenticated(user)),
         );
      },
    );
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.register(
      event.email,
      event.password,
      event.role,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      passportNumber: event.passportNumber,
      nationality: event.nationality,
    );

    await result.fold(
      (failure) async {
        emit(AuthFailureState(failure.message));
      },
      (token) async {
        final userResult = await _authRepository.getCurrentUser();
        await userResult.fold(
          (failure) async => emit(AuthFailureState("Registration success but failed to fetch user data")),
          (user) async => emit(AuthAuthenticated(user)),
        );
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
