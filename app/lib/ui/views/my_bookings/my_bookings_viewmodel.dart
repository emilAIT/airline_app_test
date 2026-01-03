import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.router.dart';
import '../../../app/app.locator.dart';
import '../../../services/booking_service.dart';
import '../../../models/booking_model.dart';

class MyBookingsViewModel extends BaseViewModel {
  final BookingService _bookingService = locator<BookingService>();
  final NavigationService _navigationService = locator<NavigationService>();

  List<BookingPublic> _bookings = [];
  List<BookingPublic> get bookings => _bookings;

  MyBookingsViewModel();

  Future<void> loadBookings() async {
    setBusy(true);
    try {
      _bookings = await _bookingService.getMyBookings();
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      setBusy(false);
    }
  }

  void viewBooking(String bookingId) {
    _navigationService.navigateTo(
      Routes.bookingDetailsView,
      arguments: BookingDetailsViewArguments(bookingId: bookingId),
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    setBusy(true);
    try {
      await _bookingService.cancelBooking(bookingId);
      await loadBookings();
    } catch (e) {
      // Handle error
    } finally {
      setBusy(false);
    }
  }
}

