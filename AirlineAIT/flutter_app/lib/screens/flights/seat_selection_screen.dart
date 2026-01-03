import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int flightId;
  final List<dynamic> passengers;

  const SeatSelectionScreen({
    super.key,
    required this.flightId,
    required this.passengers,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<String, dynamic> _seatMap = {};
  Map<String, dynamic> _template = {};
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, String?> _passengerSeats = {}; // passenger_id -> seat_number
  int? _selectedPassengerId;

  @override
  void initState() {
    super.initState();
    if (widget.passengers.isNotEmpty) {
      _selectedPassengerId = widget.passengers[0]['id'];
    }
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
          _template = Map<String, dynamic>.from(response.data['template'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load seat map: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSeatSelected(String seatNumber) {
    // If we have a selected passenger, assign to them
    if (_selectedPassengerId != null) {
      setState(() {
        _passengerSeats[_selectedPassengerId!] = seatNumber;
      });
      return;
    }

    // Fallback: Find first unassigned passenger
    int? passengerToAssign;
    for (var p in widget.passengers) {
      if (!_passengerSeats.containsKey(p['id']) || _passengerSeats[p['id']] == null) {
        passengerToAssign = p['id'];
        break;
      }
    }

    if (passengerToAssign != null) {
      setState(() {
        _passengerSeats[passengerToAssign!] = seatNumber;
        _selectedPassengerId = passengerToAssign; // Track newly assigned
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All passengers already have seats assigned. Select a passenger to change their seat.')),
      );
    }
  }

  void _removeSeat(int passengerId) {
    setState(() {
      _passengerSeats[passengerId] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seats'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(message: _errorMessage!, onRetry: _loadSeatMap)
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildLegend(),
                        Expanded(
                          child: _buildCabinLayout(),
                        ),
                        _buildPassengerBar(),
                        _buildConfirmButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor,
      child: Row(
        children: [
          const Icon(Icons.flight_class, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cabin Selection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                '${widget.passengers.length} Passenger(s)',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem('Economy', Colors.blue.shade200),
            _legendItem('Business', Colors.amber.shade600),
            _legendItem('Extra Legroom', Colors.blue.shade800),
            _legendItem('Occupied', Colors.grey.shade400),
            _legendItem('Your Choice', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCabinLayout() {
    final int rows = _template['rows'] ?? 0;
    final List<dynamic> aislePositions = _template['aisle_positions'] ?? [];
    final List<dynamic> emergencyExits = _template['emergency_exits'] ?? [];
    final List<dynamic> labels = _template['seat_labels'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 100, bottom: 40),
          itemCount: rows,
          itemBuilder: (context, index) {
            final rowNum = index + 1;
            final isExit = emergencyExits.contains(rowNum);
            
            return Column(
              children: [
                if (isExit) _buildExitMarker('EXIT'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRowHeader(rowNum),
                      ...List.generate(labels.length, (colIndex) {
                        final label = labels[colIndex];
                        final seatNum = '$rowNum$label';
                        final addAisle = aislePositions.contains(colIndex + 1);
                        
                        return Row(
                          children: [
                            _buildSeat(seatNum),
                            if (addAisle) const SizedBox(width: 24),
                          ],
                        );
                      }),
                      _buildRowHeader(rowNum),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRowHeader(int rowNum) {
    return Container(
      width: 24,
      alignment: Alignment.center,
      child: Text(
        '$rowNum',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExitMarker(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.red.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _exitIndicator(),
          Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
          _exitIndicator(),
        ],
      ),
    );
  }

  Widget _exitIndicator() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.red,
    );
  }

  Widget _buildSeat(String seatNumber) {
    final seatInfo = _seatMap[seatNumber];
    if (seatInfo == null) return const SizedBox(width: 32);

    final bool isAvailable = seatInfo['available'];
    final String category = seatInfo['category'] ?? 'STANDARD';
    final bool isSelected = _passengerSeats.values.contains(seatNumber);
    
    Color baseColor;
    switch (category) {
      case 'BUSINESS':
        baseColor = Colors.amber.shade600;
        break;
      case 'EXTRA_LEGROOM':
        baseColor = Colors.blue.shade800;
        break;
      default:
        baseColor = Colors.blue.shade200;
    }

    Color seatColor;
    if (isSelected) {
      seatColor = Colors.green;
    } else if (!isAvailable) {
      seatColor = Colors.grey.shade400;
    } else {
      seatColor = baseColor;
    }

    return GestureDetector(
      onTap: isAvailable || isSelected ? () {
        if (isSelected) {
          final pEntry = _passengerSeats.entries.firstWhere((e) => e.value == seatNumber);
          _removeSeat(pEntry.key);
        } else {
          _onSeatSelected(seatNumber);
        }
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 30,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4)] : null,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 2),
            Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Spacer(),
            Text(
              seatNumber.replaceAll(RegExp(r'[0-9]'), ''),
              style: TextStyle(
                color: (isSelected || category == 'EXTRA_LEGROOM') ? Colors.white : Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '\$${seatInfo['price']?.toInt() ?? 0}',
              style: TextStyle(
                color: (isSelected || category == 'EXTRA_LEGROOM') ? Colors.white70 : Colors.black45,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerBar() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.passengers.length,
        itemBuilder: (context, index) {
          final p = widget.passengers[index];
          final seat = _passengerSeats[p['id']];
          final isSelected = _selectedPassengerId == p['id'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPassengerId = p['id'];
              });
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.blue.withOpacity(0.1) 
                    : (seat != null ? Colors.green.withOpacity(0.05) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? Colors.blue 
                      : (seat != null ? Colors.green.withOpacity(0.5) : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 4)] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p['full_name'] ?? 'Passenger',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    ),
                  ),
                  Text(
                    seat ?? 'Not assigned',
                    style: TextStyle(
                      color: seat != null ? Colors.green : Colors.red, 
                      fontSize: 11,
                      fontWeight: seat != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    final bool allAssigned = _passengerSeats.length == widget.passengers.length && 
        _passengerSeats.values.every((s) => s != null);

    double totalPrice = 0;
    for (var seatNum in _passengerSeats.values) {
      if (seatNum != null && _seatMap[seatNum] != null) {
        totalPrice += (_seatMap[seatNum]['price'] ?? 0).toDouble();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: allAssigned ? () {
              final Map<int, Map<String, dynamic>> selectionDetails = {};
              for (var entry in _passengerSeats.entries) {
                if (entry.value != null) {
                  selectionDetails[entry.key] = {
                    'seat_number': entry.value,
                    'price': _seatMap[entry.value]['price'] ?? 0,
                  };
                }
              }
              Navigator.of(context).pop(selectionDetails);
            } : null,
            child: Text(allAssigned ? 'Confirm' : 'Select Seats'),
          ),
        ],
      ),
    );
  }
}
