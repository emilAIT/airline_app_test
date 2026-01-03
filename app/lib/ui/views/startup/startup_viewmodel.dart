import 'package:stacked/stacked.dart';
import 'package:flutter_airline_app/app/app.locator.dart';
import 'package:flutter_airline_app/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter_airline_app/services/auth_service.dart';
import 'package:flutter_airline_app/services/api_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _apiService = locator<ApiService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    await Future.delayed(const Duration(seconds: 1));

    // Check if user has a valid token
    final token = await _apiService.getToken();
    
    if (token != null && token.isNotEmpty) {
      // Token exists, try to verify it by getting current user
      try {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          // User is authenticated, go to main screen
          print('StartupViewModel: User is authenticated, navigating to FlightSearchView');
          _navigationService.replaceWith(Routes.flightSearchView);
          return;
        }
      } catch (e) {
        // Token is invalid or expired, clear it and go to login
        print('StartupViewModel: Token validation failed: $e');
        await _apiService.clearToken();
      }
    }
    
    // No token or invalid token, go to login
    print('StartupViewModel: No valid token, navigating to LoginView');
    _navigationService.replaceWith(Routes.loginView);
  }
}
