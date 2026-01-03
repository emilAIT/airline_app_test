import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airline_app/data/repositories/auth_repository.dart';
import 'package:airline_app/data/repositories/profile_repository.dart';
import 'package:airline_app/domain/entities/user.dart';
import 'package:airline_app/domain/entities/passenger_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final PassengerProfile? profile;
  
  const Authenticated(this.user, {this.profile});
  
  bool get isProfileComplete => user.role == UserRole.staff || (profile != null && profile!.isComplete);
  
  @override
  List<Object?> get props => [user, profile];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  AuthCubit(this._authRepository, this._profileRepository) : super(AuthInitial());

  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        PassengerProfile? profile;
        if (user.role == UserRole.passenger) {
          profile = await _profileRepository.getMyProfile();
        }
        emit(Authenticated(user, profile: profile));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login(String username, String password) async {
    print('🔐 Login attempt for username: $username');
    emit(AuthLoading());
    try {
      print('📡 Calling auth repository login...');
      final user = await _authRepository.login(username, password);
      print('✅ Login successful! User: ${user.username}, Role: ${user.role}');
      
      PassengerProfile? profile;
      if (user.role == UserRole.passenger) {
        print('👤 Fetching passenger profile...');
        profile = await _profileRepository.getMyProfile();
        print('✅ Profile fetched: ${profile?.firstName} ${profile?.lastName}');
      }
      print('🎉 Emitting Authenticated state');
      emit(Authenticated(user, profile: profile));
    } catch (e) {
      print('❌ Login error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String email, String username, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(email, username, password);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile(PassengerProfile profile) async {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      emit(AuthLoading());
      try {
        final updatedProfile = await _profileRepository.updateProfile(profile);
        emit(Authenticated(currentUser, profile: updatedProfile));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
