import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'manage_trips_viewmodel.dart';
import '../../../models/booking_model.dart';
import '../../../models/flight_model.dart';

class ManageTripsView extends StackedView<ManageTripsViewModel> {
  const ManageTripsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ManageTripsViewModel viewModel, Widget? child) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Trips'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            onTap: (index) => viewModel.setTabIndex(index),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent(
              context,
              viewModel,
              viewModel.upcomingBookings,
              viewModel.hasUpcomingError,
              viewModel.loadUpcomingBookings,
            ),
            _buildTabContent(
              context,
              viewModel,
              viewModel.pastBookings,
              viewModel.hasPastError,
              viewModel.loadPastBookings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    ManageTripsViewModel viewModel,
    List<BookingWithFlight> bookings,
    bool hasError,
    Future<void> Function() loadFunction,
  ) {
    if (viewModel.isBusy && bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadFunction,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadFunction,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadFunction,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final bookingWithFlight = bookings[index];
          return _buildBookingCard(context, viewModel, bookingWithFlight);
        },
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    ManageTripsViewModel viewModel,
    BookingWithFlight bookingWithFlight,
  ) {
    final booking = bookingWithFlight.booking;
    final flight = bookingWithFlight.flight;
    final route = viewModel.getRoute(bookingWithFlight);
    final routeFull = viewModel.getRouteFull(bookingWithFlight);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => viewModel.viewBookingDetails(booking.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PNR and Status Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PNR: ${booking.pnr}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route
              Row(
                children: [
                  Icon(
                    Icons.flight,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (routeFull != route)
                          Text(
                            routeFull,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (flight != null) ...[
                const SizedBox(height: 12),
                // Departure Date/Time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Departure: ${DateFormat('MMM dd, yyyy • HH:mm').format(flight.departureTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Flight Status
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Flight Status: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getFlightStatusColor(flight.status)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              flight.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getFlightStatusColor(flight.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Created date
              Text(
                'Booked: ${DateFormat('MMM dd, yyyy').format(booking.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.created:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getFlightStatusColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.scheduled:
        return Colors.blue;
      case FlightStatus.boarding:
        return Colors.orange;
      case FlightStatus.delayed:
        return Colors.red;
      case FlightStatus.cancelled:
        return Colors.red;
      case FlightStatus.departed:
        return Colors.purple;
      case FlightStatus.landed:
        return Colors.green;
    }
  }

  @override
  ManageTripsViewModel viewModelBuilder(BuildContext context) =>
      ManageTripsViewModel();

  @override
  void onViewModelReady(ManageTripsViewModel viewModel) {
    viewModel.loadUpcomingBookings();
  }
}

