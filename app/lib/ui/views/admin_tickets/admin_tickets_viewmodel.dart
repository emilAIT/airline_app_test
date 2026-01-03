import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:intl/intl.dart';
import '../../../app/app.locator.dart';
import '../../../services/ticket_service.dart';
import '../../../models/ticket_model.dart';

class AdminTicketsViewModel extends BaseViewModel {
  final TicketService _ticketService = TicketService();
  final NavigationService _navigationService = locator<NavigationService>();

  List<TicketPublic> _tickets = [];
  List<TicketPublic> get tickets => _tickets;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String? _searchTicketNumber;
  String? get searchTicketNumber => _searchTicketNumber;

  Future<void> loadTickets() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _ticketService.getAllTickets(limit: 200);
      // Sort by created_at descending (newest first)
      _tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _tickets = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> searchByTicketNumber(String ticketNumber) async {
    if (ticketNumber.isEmpty) {
      await loadTickets();
      return;
    }

    setBusy(true);
    _errorMessage = null;
    _searchTicketNumber = ticketNumber;
    notifyListeners();

    try {
      final ticket = await _ticketService.searchTicketByNumber(ticketNumber);
      _tickets = [ticket];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _tickets = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void clearSearch() {
    _searchTicketNumber = null;
    loadTickets();
  }

  void viewTicketDetails(BuildContext context, TicketPublic ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket Details - ${ticket.ticketNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Ticket Number', ticket.ticketNumber),
              _buildDetailRow('Passenger Name', ticket.passengerName),
              _buildDetailRow('Seat Number', ticket.seatNumber),
              _buildDetailRow('Booking ID', ticket.bookingId),
              if (ticket.flightSeatId != null)
                _buildDetailRow('Flight Seat ID', ticket.flightSeatId!),
              _buildDetailRow(
                'Created',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(ticket.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

