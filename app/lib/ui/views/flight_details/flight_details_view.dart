import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'flight_details_viewmodel.dart';
import '../../../models/flight_model.dart';

class FlightDetailsView extends StackedView<FlightDetailsViewModel> {
  final String flightId;

  const FlightDetailsView({
    Key? key,
    required this.flightId,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, FlightDetailsViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: viewModel.isBusy
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
                          'Error loading flight details',
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
                          onPressed: viewModel.loadFlightDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
          : viewModel.flight == null
              ? const Center(child: Text('No flight data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFlightInfoCard(context, viewModel.flight!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFlightInfoCard(BuildContext context, FlightPublic flight) {
    final duration = flight.arrivalTime.difference(flight.departureTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Flight ${flight.flightNumber}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flight.status)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    flight.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(flight.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(flight.departureTime),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.departureTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Departure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(flight.arrivalTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arrival',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (flight.gate != null || flight.terminal != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  if (flight.gate != null) ...[
                    Icon(Icons.meeting_room, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Gate: ${flight.gate}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (flight.terminal != null) ...[
                    const SizedBox(width: 24),
                    Icon(Icons.business, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Terminal: ${flight.terminal}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
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
  FlightDetailsViewModel viewModelBuilder(BuildContext context) =>
      FlightDetailsViewModel(flightId: flightId);

  @override
  void onViewModelReady(FlightDetailsViewModel viewModel) {
    viewModel.loadFlightDetails();
  }
}

