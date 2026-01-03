import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../models/user_model.dart';
import '../../../models/booking_model.dart';

class ProfileViewModel extends BaseViewModel {
  final _authService = locator<AuthService>();
  final _bookingService = locator<BookingService>();
  final _navigationService = locator<NavigationService>();

  UserPublic? _user;
  UserPublic? get user => _user;

  PassengerProfilePublic? _profile;
  PassengerProfilePublic? get profile => _profile;

  List<BookingPublic> _bookings = [];
  List<BookingPublic> get bookings => _bookings;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _cachedEmail;
  String? get cachedEmail => _cachedEmail;
  
  bool get isAdmin => _cachedEmail?.toLowerCase() == 'admin@example.com' || 
                      _user?.email.toLowerCase() == 'admin@example.com' ||
                      _user?.role == UserRole.staff;

  ProfileViewModel();

  Future<void> loadUserData() async {
    setBusy(true);
    _errorMessage = null;
    
    try {
      // Get cached email first (for fallback display)
      _cachedEmail = await _authService.getCachedUserEmail();
      print('ProfileViewModel: Cached email: $_cachedEmail');
      
      // Load user data from /users/me endpoint
      print('ProfileViewModel: Loading user data...');
      _user = await _authService.getCurrentUser();
      print('ProfileViewModel: User loaded successfully - Email: ${_user?.email}, Role: ${_user?.role}');
      
      // Load bookings
      try {
        print('ProfileViewModel: Loading bookings...');
        _bookings = await _bookingService.getMyBookings();
        print('ProfileViewModel: Bookings loaded - Count: ${_bookings.length}');
      } catch (e) {
        // If bookings fail, continue without them
        _bookings = [];
        print('ProfileViewModel: Failed to load bookings - $e');
      }
      
      notifyListeners();
    } catch (e) {
      final errorString = e.toString().replaceAll('Exception: ', '').replaceAll('Get user error: ', '');
      print('ProfileViewModel: Failed to load user data: $e');
      _errorMessage = errorString;
      notifyListeners();
      
      // If it's an authentication error, automatically redirect to login after a short delay
      if (errorString.contains('No authentication token') || 
          errorString.contains('Authentication failed') ||
          errorString.contains('User not found') ||
          errorString.contains('Please login again')) {
        print('ProfileViewModel: Authentication error detected, redirecting to login...');
        Future.delayed(const Duration(seconds: 2), () {
          navigateToLogin();
        });
      }
    } finally {
      setBusy(false);
    }
  }

  void navigateToLogin() {
    _navigationService.replaceWith(Routes.loginView);
  }

  Future<void> logout() async {
    setBusy(true);
    try {
      await _authService.logout();
      _navigationService.replaceWith(Routes.loginView);
    } catch (e) {
      print('ProfileViewModel: Logout error - $e');
      // Even if logout fails, navigate to login
      _navigationService.replaceWith(Routes.loginView);
    } finally {
      setBusy(false);
    }
  }
}

