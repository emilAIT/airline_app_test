import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../services/airport_service.dart';
import '../../../models/airport_model.dart';
import '../update_airport/update_airport_viewmodel.dart' as update_airport;

class AdminAirportsViewModel extends BaseViewModel {
  final AirportService _airportService = AirportService();
  final NavigationService _navigationService = locator<NavigationService>();

  List<AirportPublic> _airports = [];
  List<AirportPublic> get airports => _airports;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadAirports() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _airports = await _airportService.getAirports();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void navigateToCreateAirport() {
    _navigationService.navigateTo(Routes.createAirportView);
  }

  void navigateToUpdateAirport(AirportPublic airport) {
    _navigationService.navigateToUpdateAirportView(
      args: update_airport.UpdateAirportViewArguments(airport: airport),
    );
  }

  void showDeleteDialog(BuildContext context, AirportPublic airport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Airport'),
        content: Text(
          'Are you sure you want to delete airport ${airport.code} (${airport.name})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteAirport(context, airport);
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

  Future<void> deleteAirport(BuildContext context, AirportPublic airport) async {
    setBusy(true);
    try {
      await _airportService.deleteAirport(airport.id);
      await loadAirports();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airport deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
}
