import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class AdminSeatMapScreen extends StatefulWidget {
  final int flightId;
  final String flightNumber;

  const AdminSeatMapScreen({
    super.key,
    required this.flightId,
    required this.flightNumber,
  });

  @override
  State<AdminSeatMapScreen> createState() => _AdminSeatMapScreenState();
}

class _AdminSeatMapScreenState extends State<AdminSeatMapScreen> {
  Map<String, dynamic> _seatMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getSeatMap(widget.flightId);
      
      if (mounted) {
        setState(() {
          _seatMap = Map<String, dynamic>.from(response.data['seat_map']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load seat map';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seat Map - ${widget.flightNumber}')),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadSeatMap)
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem(Colors.blue.shade200, 'Economy'),
                          _buildLegendItem(Colors.amber.shade600, 'Business'),
                          _buildLegendItem(Colors.blue.shade800, 'Extra Legroom'),
                          _buildLegendItem(Colors.grey, 'Booked'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '💡 Tap any BOOKED seat to view passenger information.',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _buildSeatGrid(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildSeatGrid() {
    final Map<int, List<String>> rows = {};
    for (var seat in _seatMap.keys) {
      final row = int.tryParse(seat.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (!rows.containsKey(row)) rows[row] = [];
      rows[row]!.add(seat);
    }

    final sortedRowKeys = rows.keys.toList()..sort();

    return InteractiveViewer(
      maxScale: 5.0,
      minScale: 0.1,
      boundaryMargin: const EdgeInsets.all(400),
      constrained: false, // Allows panning child of any size
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: sortedRowKeys.map((rowNum) {
              final seatsInRow = rows[rowNum]!..sort();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('$rowNum', style: const TextStyle(fontWeight: FontWeight.bold))
                    ),
                    ...seatsInRow.map((seat) => _buildSeat(seat)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSeat(String seatNumber) {
    final seatInfo = _seatMap[seatNumber];
    if (seatInfo == null) return const SizedBox(width: 32);
    
    final bool isAvailable = seatInfo['available'];
    final passengerInfo = seatInfo['passenger_info'];
    final String category = seatInfo['category'] ?? 'STANDARD';
    
    Color seatColor;
    if (isAvailable) {
      switch (category) {
        case 'BUSINESS':
          seatColor = Colors.amber.shade600;
          break;
        case 'EXTRA_LEGROOM':
          seatColor = Colors.blue.shade800;
          break;
        default:
          seatColor = Colors.blue.shade200;
      }
    } else {
      seatColor = Colors.grey;
    }
    
    return GestureDetector(
      onTap: () {
        if (!isAvailable && passengerInfo != null) {
          _showPassengerDetails(seatNumber, passengerInfo);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(4),
          border: !isAvailable ? Border.all(color: Colors.black26) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              seatNumber.replaceAll(RegExp(r'[0-9]'), ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${seatInfo['price']?.toInt() ?? 0}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassengerDetails(String seatNumber, Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Seat $seatNumber Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', info['passenger_name']),
            const SizedBox(height: 8),
            _buildInfoRow('PNR', info['pnr']),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Status', 
              info['is_checked_in'] == true ? 'Checked In' : 'Pending',
              color: info['is_checked_in'] == true ? Colors.green : Colors.orange,
            ),
          ],
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
