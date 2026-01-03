import 'dart:convert';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../services/booking_service.dart';
import '../../../services/api_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/ticket_model.dart';

class BookingDetailsViewModel extends BaseViewModel {
  final BookingService _bookingService = locator<BookingService>();
  final ApiService _apiService = locator<ApiService>();

  final String bookingId;
  BookingPublic? _booking;
  BookingPublic? get booking => _booking;

  List<TicketPublic> _tickets = [];
  List<TicketPublic> get tickets => _tickets;

  BookingDetailsViewModel({
    required this.bookingId,
  });


  Future<void> loadBooking() async {
    setBusy(true);
    try {
      _booking = await _bookingService.getBooking(bookingId);
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadTickets() async {
    try {
      final response = await _apiService.get(
        '/tickets/booking/$bookingId',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tickets = data.map((json) => TicketPublic.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }
}

