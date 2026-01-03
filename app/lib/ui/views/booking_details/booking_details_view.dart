import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'booking_details_viewmodel.dart';

class BookingDetailsView extends StackedView<BookingDetailsViewModel> {
  final String bookingId;

  const BookingDetailsView({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, BookingDetailsViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PNR: ${viewModel.booking!.pnr}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Status: ${viewModel.booking!.status.name}'),
                              Text(
                                  'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(viewModel.booking!.createdAt)}'),
                            ],
                          ),
                        ),
                      ),
                      if (viewModel.tickets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Tickets',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...viewModel.tickets.map((ticket) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(ticket.passengerName),
                                subtitle: Text(
                                    'Ticket: ${ticket.ticketNumber}\nSeat: ${ticket.seatNumber}'),
                                leading: const Icon(Icons.confirmation_number),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }

  @override
  BookingDetailsViewModel viewModelBuilder(BuildContext context) =>
      BookingDetailsViewModel(bookingId: bookingId);
}

