import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/flight_service.dart';
import '../../../models/flight_model.dart';
import '../create_flight/create_flight_view.dart';
import '../update_flight/update_flight_view.dart';
import '../create_flight/create_flight_view.dart';
import '../update_flight/update_flight_view.dart';

class AdminFlightsViewModel extends BaseViewModel {
  final FlightService _flightService = locator<FlightService>();
  final NavigationService _navigationService = locator<NavigationService>();

  List<FlightPublic> _flights = [];
  List<FlightPublic> get flights => _flights;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadFlights() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _flights = await _flightService.getFlights(limit: 200);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void navigateToCreateFlight() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateFlightView()),
      );
    }
  }

  void navigateToUpdateFlight(FlightPublic flight) {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateFlightView(
            args: UpdateFlightViewArguments(flight: flight),
          ),
        ),
      );
    }
  }

  void navigateToFlightDetails(String flightId) {
    _navigationService.navigateTo(
      Routes.flightDetailsView,
      arguments: FlightDetailsViewArguments(flightId: flightId),
    );
  }

  void showUpdateStatusDialog(BuildContext context, FlightPublic flight) {
    FlightStatus? selectedStatus = flight.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Flight Status'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Flight: ${flight.flightNumber}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<FlightStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: FlightStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedStatus != null
                ? () async {
                    Navigator.pop(context);
                    await updateFlightStatus(flight.id, selectedStatus!);
                  }
                : null,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void showUpdateGateTerminalDialog(BuildContext context, FlightPublic flight) {
    final gateController = TextEditingController(text: flight.gate ?? '');
    final terminalController = TextEditingController(text: flight.terminal ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Gate/Terminal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Flight: ${flight.flightNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: gateController,
              decoration: const InputDecoration(
                labelText: 'Gate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: terminalController,
              decoration: const InputDecoration(
                labelText: 'Terminal',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await updateGateTerminal(
                flight.id,
                gateController.text.isEmpty ? null : gateController.text,
                terminalController.text.isEmpty ? null : terminalController.text,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void showDeleteDialog(BuildContext context, FlightPublic flight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flight'),
        content: Text(
          'Are you sure you want to delete flight ${flight.flightNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteFlight(flight.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> updateFlightStatus(String flightId, FlightStatus status) async {
    setBusy(true);
    try {
      await _flightService.updateFlightStatus(
        flightId,
        FlightStatusUpdate(status: status),
      );
      await loadFlights();
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(content: Text('Flight status updated successfully')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }

  Future<void> updateGateTerminal(
    String flightId,
    String? gate,
    String? terminal,
  ) async {
    setBusy(true);
    try {
      await _flightService.updateFlightGateTerminal(
        flightId,
        FlightGateTerminalUpdate(gate: gate, terminal: terminal),
      );
      await loadFlights();
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(content: Text('Gate/Terminal updated successfully')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }

  Future<void> deleteFlight(String flightId) async {
    setBusy(true);
    try {
      await _flightService.deleteFlight(flightId);
      await loadFlights();
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(content: Text('Flight deleted successfully')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }

  BuildContext? get context => _navigationService.navigatorKey?.currentContext;
}

