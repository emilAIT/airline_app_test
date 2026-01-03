import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'flight_results_viewmodel.dart';
import '../../../models/flight_model.dart';
import '../../widgets/scaffold_with_drawer.dart';

class FlightResultsView extends StackedView<FlightResultsViewModel> {
  final List<FlightSearchResult>? initialFlights;
  final FlightSearchParams? searchParams;

  const FlightResultsView({
    Key? key,
    this.initialFlights,
    this.searchParams,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, FlightResultsViewModel viewModel, Widget? child) {
    return ScaffoldWithDrawer(
      title: 'Flight Results',
      body: viewModel.isBusy && viewModel.flights.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
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
                          'Error loading flights',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: viewModel.loadFlights,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
          : viewModel.isEmpty
              ? Center(
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
                        'No flights found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search criteria',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.refreshFlights,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: viewModel.flights.length,
                    itemBuilder: (context, index) {
                      final flight = viewModel.flights[index];
                      return _buildFlightCard(context, viewModel, flight);
                    },
                  ),
                ),
    );
  }

  Widget _buildFlightCard(
    BuildContext context,
    FlightResultsViewModel viewModel,
    FlightSearchResult flight,
  ) {
    final duration = Duration(minutes: flight.durationMinutes);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () => viewModel.navigateToBooking(flight.flightId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flight ${flight.flightNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${flight.originAirportCode} → ${flight.destinationAirportCode}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(flight.status)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            flight.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(flight.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(flight.departureTime),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.flight,
                        color: Colors.blue.shade700,
                      ),
                      Text(
                        durationText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(flight.arrivalTime),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Arrival',
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
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 20,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${flight.priceFrom}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${flight.availableSeats} seats',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.scheduled:
        return Colors.blue;
      case FlightStatus.boarding:
        return Colors.orange;
      case FlightStatus.delayed:
        return Colors.red;
      case FlightStatus.cancelled:
        return Colors.grey;
      case FlightStatus.departed:
        return Colors.purple;
      case FlightStatus.landed:
        return Colors.green;
    }
  }

  @override
  FlightResultsViewModel viewModelBuilder(BuildContext context) =>
      FlightResultsViewModel(
        initialFlights: initialFlights,
        searchParams: searchParams,
      );

  @override
  void onViewModelReady(FlightResultsViewModel viewModel) {
    // Load flights if initial flights not provided
    if (initialFlights == null || initialFlights!.isEmpty) {
      viewModel.loadFlights();
    }
  }
}

