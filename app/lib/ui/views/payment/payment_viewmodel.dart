import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.router.dart';
import '../../../app/app.locator.dart';
import '../../../services/payment_service.dart';
import '../../../services/booking_service.dart';
import '../../../models/payment_model.dart' as models;
import '../../../models/booking_model.dart';

class PaymentViewModel extends BaseViewModel {
  final PaymentService _paymentService = locator<PaymentService>();
  final BookingService _bookingService = locator<BookingService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final String bookingId;
  models.PaymentMethod? _selectedMethod;
  models.PaymentMethod? get selectedMethod => _selectedMethod;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  models.PaymentPublic? _createdPayment;
  models.PaymentPublic? get createdPayment => _createdPayment;

  BookingPublic? _booking;
  BookingPublic? get booking => _booking;

  bool _paymentSuccess = false;
  bool get paymentSuccess => _paymentSuccess;

  PaymentViewModel({
    required this.bookingId,
  });

  @override
  void onViewModelReady() {
    loadBooking();
  }

  Future<void> loadBooking() async {
    try {
      _booking = await _bookingService.getBooking(bookingId);
      notifyListeners();
    } catch (e) {
      print('Error loading booking: $e');
      // Don't show error, just continue
    }
  }

  void setPaymentMethod(models.PaymentMethod? method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<void> processPayment() async {
    if (_selectedMethod == null) return;

    _errorMessage = null;
    _paymentSuccess = false;
    notifyListeners();

    setBusy(true);

    try {
      print('PaymentViewModel: Creating payment for booking: $bookingId');
      _createdPayment = await _paymentService.createPayment(
        bookingId: bookingId,
        method: _selectedMethod!,
      );

      print('PaymentViewModel: Payment created successfully. Status: ${_createdPayment!.status}');
      
      // Reload booking to get updated status (CONFIRMED after payment)
      await loadBooking();
      
      _paymentSuccess = true;
      notifyListeners();

      // Navigate to bookings after 2 seconds to show success message
      await Future.delayed(const Duration(seconds: 2));
      _navigationService.replaceWith(Routes.myBookingsView);
    } catch (e) {
      print('PaymentViewModel: Payment error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}

