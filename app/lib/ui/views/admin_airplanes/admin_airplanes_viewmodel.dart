import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/airplane_service.dart';
import '../../../models/airplane_model.dart';
import '../create_airplane/create_airplane_view.dart';
import '../update_airplane/update_airplane_view.dart';

class AdminAirplanesViewModel extends BaseViewModel {
  final AirplaneService _airplaneService = AirplaneService();
  final NavigationService _navigationService = locator<NavigationService>();

  List<AirplanePublic> _airplanes = [];
  List<AirplanePublic> get airplanes => _airplanes;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadAirplanes() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _airplanes = await _airplaneService.getAirplanes();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void navigateToCreateAirplane() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAirplaneView(),
        ),
      ).then((_) => loadAirplanes());
    }
  }

  void navigateToUpdateAirplane(AirplanePublic airplane) {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateAirplaneView(
            args: UpdateAirplaneViewArguments(airplane: airplane),
          ),
        ),
      ).then((_) => loadAirplanes());
    }
  }

  void showDeleteDialog(BuildContext context, AirplanePublic airplane) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Airplane'),
        content: Text(
          'Are you sure you want to delete airplane ${airplane.model}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteAirplane(airplane.id);
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

  Future<void> deleteAirplane(String airplaneId) async {
    setBusy(true);
    try {
      await _airplaneService.deleteAirplane(airplaneId);
      await loadAirplanes();
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airplane deleted successfully')),
        );
      }
    } catch (e) {
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
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

  Future<void> showSeatMap(BuildContext context, AirplanePublic airplane) async {
    try {
      setBusy(true);
      final seatMap = await _airplaneService.getSeatMap(airplane.id);
      setBusy(false);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => _SeatMapDialog(airplane: airplane, seatMap: seatMap),
        );
      }
    } catch (e) {
      setBusy(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading seat map: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SeatMapDialog extends StatelessWidget {
  final AirplanePublic airplane;
  final AirplaneSeatMapResponse seatMap;

  const _SeatMapDialog({
    required this.airplane,
    required this.seatMap,
  });

  @override
  Widget build(BuildContext context) {
    // Group seats by row
    final seatsByRow = <int, List<SeatTemplateBase>>{};
    for (var seat in seatMap.seatMap) {
      if (!seatsByRow.containsKey(seat.row)) {
        seatsByRow[seat.row] = [];
      }
      seatsByRow[seat.row]!.add(seat);
    }

    // Sort rows
    final sortedRows = seatsByRow.keys.toList()..sort();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seat Map: ${airplane.model}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Seats: ${seatMap.totalSeats}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Legend
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(Colors.blue, 'Standard'),
                  _buildLegendItem(Colors.orange, 'Extra Legroom'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Seat map
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flight, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Cabin Layout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rows
                      ...sortedRows.map((row) => _buildSeatRow(row, seatsByRow[row]!)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildSeatRow(int row, List<SeatTemplateBase> seats) {
    // Sort seats by seat_label
    final sortedSeats = List<SeatTemplateBase>.from(seats);
    sortedSeats.sort((a, b) => a.seatLabel.compareTo(b.seatLabel));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row number
          SizedBox(
            width: 40,
            child: Text(
              '$row',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Seats
          ...sortedSeats.map((seat) => _buildSeatButton(seat)),
        ],
      ),
    );
  }

  Widget _buildSeatButton(SeatTemplateBase seat) {
    final color = seat.category == SeatCategory.extraLegroom
        ? Colors.orange
        : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(
            color: color,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            seat.seatLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

