import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight.dart';
import '../services/flight_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'package:dio/dio.dart';

final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.read(dioProvider));
});

class SeatMapScreen extends ConsumerStatefulWidget {
  final Flight flight;
  final Function(String seatNumber)? onSeatSelected;
  final String? selectedSeat;

  const SeatMapScreen({
    super.key,
    required this.flight,
    this.onSeatSelected,
    this.selectedSeat,
  });

  @override
  ConsumerState<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends ConsumerState<SeatMapScreen> {
  List<SeatStatus> _seats = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _selectedSeat = widget.selectedSeat;
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flightService = ref.read(flightServiceProvider);
      final authState = ref.read(authProvider);
      final seats = await flightService.getFlightSeats(
        widget.flight.id,
        token: authState.token, // Pass token for authenticated requests
      );

      if (mounted) {
        setState(() {
          _seats = seats;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _seats = []; // Clear seats on error
        });
      }
    }
  }

  void _selectSeat(String seatNumber) {
    final seat = _seats.firstWhere((s) => s.seatNumber == seatNumber);
    
    // Can only select available seats
    if (seat.isOccupied || seat.isHeld) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This seat is not available')),
      );
      return;
    }

    setState(() {
      _selectedSeat = seatNumber;
    });

    if (widget.onSeatSelected != null) {
      widget.onSeatSelected!(seatNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seat Map - ${widget.flight.flightNumber}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedSeat != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedSeat);
              },
              child: const Text(
                'Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading seat map',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadSeats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Legend
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.surfaceColor,
                      child: Column(
                        children: [
                          // Seat status legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem(const Color(0xFF10B981), 'Available'),
                              _buildLegendItem(const Color(0xFF64748B), 'Occupied'),
                              _buildLegendItem(const Color(0xFFF59E0B), 'Held'),
                              _buildLegendItem(AppTheme.primaryColor, 'Selected'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Category legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem(Colors.blue, 'Standard'),
                              _buildLegendItem(Colors.purple, 'Extra Legroom'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Seat Map
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildSeatMap(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSeatMap() {
    if (_seats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No seats available for this flight',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Group seats by row
    Map<String, List<SeatStatus>> seatsByRow = {};
    for (var seat in _seats) {
      // Extract row number (e.g., "12A" -> "12", "1A" -> "1")
      final rowMatch = RegExp(r'^\d+').firstMatch(seat.seatNumber);
      if (rowMatch != null) {
        final row = rowMatch.group(0)!;
        seatsByRow.putIfAbsent(row, () => []).add(seat);
      }
    }

    // Sort rows numerically
    final sortedRows = seatsByRow.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    if (sortedRows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Unable to parse seat layout',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Determine category boundaries
    String? standardStartRow;
    String? extraLegroomStartRow;
    
    // Find first row of each category
    for (var row in sortedRows) {
      final seatsInRow = seatsByRow[row]!;
      if (seatsInRow.isNotEmpty) {
        final category = seatsInRow.first.category.toLowerCase();
        if (category.contains('standard') || category == 'economy') {
          standardStartRow ??= row;
        } else if (category.contains('extra') || category.contains('legroom') || category == 'business') {
          extraLegroomStartRow ??= row;
        }
      }
    }

    return Column(
      children: [
        // Aircraft front indicator
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Front',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Seat rows with category labels
        ...sortedRows.map((row) {
          final seatsInRow = seatsByRow[row]!;
          final category = seatsInRow.isNotEmpty ? seatsInRow.first.category.toLowerCase() : '';
          final isStandardStart = (category.contains('standard') || category == 'economy') && row == standardStartRow;
          final isExtraLegroomStart = (category.contains('extra') || category.contains('legroom') || category == 'business') && row == extraLegroomStartRow;
          
          return Column(
            children: [
              // Category label divider
              if (isExtraLegroomStart || isStandardStart)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isExtraLegroomStart 
                        ? Colors.purple.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isExtraLegroomStart ? Colors.purple : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExtraLegroomStart 
                            ? 'Extra Legroom Category (starts from row $row)'
                            : 'Standard Category (starts from row $row)',
                        style: TextStyle(
                          color: isExtraLegroomStart ? Colors.purple[700] : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSeatRow(row, seatsInRow),
            ],
          );
        }),
        const SizedBox(height: 16),
        // Aircraft back indicator
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_land, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Back',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeatRow(String rowNumber, List<SeatStatus> seats) {
    // Create a copy and sort seats by letter (A, B, C, etc.)
    final sortedSeats = List<SeatStatus>.from(seats);
    sortedSeats.sort((a, b) {
      final aLetter = a.seatNumber.replaceAll(RegExp(r'^\d+'), '');
      final bLetter = b.seatNumber.replaceAll(RegExp(r'^\d+'), '');
      return aLetter.compareTo(bLetter);
    });

    // Calculate aisle position (middle of seats)
    final halfCount = sortedSeats.length ~/ 2;
    final leftSeats = sortedSeats.take(halfCount).toList();
    final rightSeats = sortedSeats.skip(halfCount).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Row number
          SizedBox(
            width: 40,
            child: Text(
              rowNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Left side seats
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: leftSeats.map((seat) => _buildSeat(seat)).toList(),
            ),
          ),
          // Aisle
          const SizedBox(width: 32),
          // Right side seats
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rightSeats.map((seat) => _buildSeat(seat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(SeatStatus seat) {
    Color seatColor = Colors.green;
    bool isSelectable = false;
    Color categoryColor = Colors.transparent;

    // Determine category color
    final category = seat.category.toLowerCase();
    if (category.contains('extra') || category.contains('legroom') || category == 'business') {
      categoryColor = Colors.purple;
    } else if (category.contains('standard') || category == 'economy') {
      categoryColor = Colors.blue;
    }

    if (_selectedSeat == seat.seatNumber) {
      seatColor = AppTheme.primaryColor;
      isSelectable = true;
    } else if (seat.isOccupied) {
      seatColor = Colors.grey;
    } else if (seat.isHeld) {
      seatColor = Colors.orange;
    } else {
      isSelectable = true;
    }

    return GestureDetector(
      onTap: isSelectable ? () => _selectSeat(seat.seatNumber) : null,
      child: Container(
        width: 45,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seatColor.withOpacity(0.2),
          border: Border.all(
            color: seatColor,
            width: _selectedSeat == seat.seatNumber ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  seat.seatNumber.replaceAll(RegExp(r'^\d+'), ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: seatColor,
                  ),
                ),
              ],
            ),
            // Category indicator (small dot at top)
            if (categoryColor != Colors.transparent)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

