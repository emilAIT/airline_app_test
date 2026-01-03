import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:intl/intl.dart';
import 'admin_flights_viewmodel.dart';
import '../../../models/flight_model.dart';

@StackedRoute()
class AdminFlightsView extends StackedView<AdminFlightsViewModel> {
  const AdminFlightsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, AdminFlightsViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flights Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => viewModel.navigateToCreateFlight(),
            tooltip: 'Create Flight',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.loadFlights,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading flights',
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
                        onPressed: viewModel.loadFlights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : viewModel.flights.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flight, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No flights found',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => viewModel.navigateToCreateFlight(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Flight'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: viewModel.loadFlights,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: viewModel.flights.length,
                        itemBuilder: (context, index) {
                          final flight = viewModel.flights[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: Icon(
                                Icons.flight,
                                size: 40,
                                color: _getStatusColor(flight.status),
                              ),
                              title: Text(
                                flight.flightNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    '${DateFormat('yyyy-MM-dd HH:mm').format(flight.departureTime)} → ${DateFormat('HH:mm').format(flight.arrivalTime)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${flight.status.name.toUpperCase()}',
                                    style: TextStyle(
                                        color: _getStatusColor(flight.status),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (flight.gate != null || flight.terminal != null)
                                    Text(
                                      'Gate: ${flight.gate ?? 'N/A'}, Terminal: ${flight.terminal ?? 'N/A'}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      viewModel.navigateToFlightDetails(flight.id);
                                      break;
                                    case 'edit':
                                      viewModel.navigateToUpdateFlight(flight);
                                      break;
                                    case 'status':
                                      viewModel.showUpdateStatusDialog(context, flight);
                                      break;
                                    case 'gate':
                                      viewModel.showUpdateGateTerminalDialog(context, flight);
                                      break;
                                    case 'delete':
                                      viewModel.showDeleteDialog(context, flight);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 20),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(Icons.update, size: 20),
                                        SizedBox(width: 8),
                                        Text('Update Status'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'gate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.airport_shuttle, size: 20),
                                        SizedBox(width: 8),
                                        Text('Update Gate/Terminal'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
  AdminFlightsViewModel viewModelBuilder(BuildContext context) =>
      AdminFlightsViewModel();

  @override
  void onViewModelReady(AdminFlightsViewModel viewModel) {
    viewModel.loadFlights();
  }
}

