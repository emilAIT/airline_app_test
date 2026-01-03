import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'admin_bookings_viewmodel.dart';
import '../../../models/booking_model.dart';
import '../../widgets/scaffold_with_drawer.dart';

class AdminBookingsView extends StackedView<AdminBookingsViewModel> {
  const AdminBookingsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminBookingsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Bookings Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.loadBookings,
          tooltip: 'Refresh',
        ),
      ],
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading bookings',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: viewModel.loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_online, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: viewModel.loadBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadBookings,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.blue.shade50,
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Total bookings: ${viewModel.bookings.length}',
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: viewModel.bookings.length,
                              itemBuilder: (context, index) {
                                final booking = viewModel.bookings[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: _getStatusColor(booking.status).withOpacity(0.2),
                                              child: Icon(
                                                _getStatusIcon(booking.status),
                                                color: _getStatusColor(booking.status),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'PNR: ${booking.pnr}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 18),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(booking.status).withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _getStatusText(booking.status),
                                                      style: TextStyle(
                                                        color: _getStatusColor(booking.status),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Divider(color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.flight,
                                          'Flight ID',
                                          booking.flightId,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.calendar_today,
                                          'Created',
                                          DateFormat('yyyy-MM-dd HH:mm').format(booking.createdAt),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => viewModel.viewBookingDetails(context, booking),
                                              icon: const Icon(Icons.visibility, size: 18),
                                              label: const Text('View Details'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade700,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                            if (booking.status != BookingStatus.cancelled) ...[
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => viewModel.showCancelDialog(context, booking),
                                                icon: const Icon(Icons.cancel, size: 18),
                                                label: const Text('Cancel'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.created:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.created:
        return Icons.pending;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.created:
        return 'CREATED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  AdminBookingsViewModel viewModelBuilder(BuildContext context) =>
      AdminBookingsViewModel();

  @override
  void onViewModelReady(AdminBookingsViewModel viewModel) {
    viewModel.loadBookings();
  }
}
