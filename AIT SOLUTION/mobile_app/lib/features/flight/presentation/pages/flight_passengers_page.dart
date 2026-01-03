import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';
import 'package:ait_airlines/core/di/injection.dart';
import 'package:ait_airlines/core/network/api_client.dart';

class FlightPassengersPage extends StatefulWidget {
  final int flightId;
  
  const FlightPassengersPage({super.key, required this.flightId});

  @override
  State<FlightPassengersPage> createState() => _FlightPassengersPageState();
}

class _FlightPassengersPageState extends State<FlightPassengersPage> {
  final ApiClient _apiClient = getIt<ApiClient>();
  Map<String, dynamic>? _passengersData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.dio.get('/flights/${widget.flightId}/passengers');
      setState(() {
        _passengersData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _reassignSeat(int ticketId, int currentSeatId) async {
    // Show dialog to select new seat
    final seats = await _loadAvailableSeats();
    if (seats == null || seats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available seats')),
      );
      return;
    }

    final selectedSeat = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SeatSelectionDialog(seats: seats),
    );

    if (selectedSeat == null) return;

    try {
      await _apiClient.dio.post(
        '/bookings/tickets/$ticketId/reassign-seat',
        data: {'new_seat_id': selectedSeat['id']},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat reassigned successfully'), backgroundColor: Colors.green),
      );
      
      _loadPassengers();
    } catch (e) {
      String errorMessage = 'Error reassigning seat';
      if (e.toString().contains('already taken')) {
        errorMessage = 'This seat is already taken. Please select another seat.';
      } else if (e.toString().contains('already assigned')) {
        errorMessage = 'Passenger is already assigned to this seat.';
      } else if (e.toString().contains('DioException')) {
        // Try to extract error message from response
        try {
          final dioError = e as dynamic;
          if (dioError.response?.data != null) {
            final data = dioError.response.data;
            if (data is Map && data['detail'] != null) {
              errorMessage = data['detail'].toString();
            }
          }
        } catch (_) {
          errorMessage = 'Error reassigning seat. Please try again.';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _loadAvailableSeats() async {
    try {
      final response = await _apiClient.dio.get('/flights/${widget.flightId}/seats');
      final seats = (response.data as List)
          .cast<Map<String, dynamic>>()
          .where((seat) => seat['is_available'] == true)
          .toList();
      return seats;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          _passengersData != null 
              ? 'Passengers - ${_passengersData!['flight_number']}'
              : 'Passengers',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPassengers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => navigateToHome(context),
            tooltip: 'Home',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading passengers',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPassengers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _passengersData == null
                  ? const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : _buildPassengersList(),
    );
  }

  Widget _buildPassengersList() {
    final passengers = _passengersData!['passengers'] as List;
    final totalPassengers = _passengersData!['total_passengers'] ?? 0;
    final checkedInCount = _passengersData!['checked_in_count'] ?? 0;

    return Column(
      children: [
        // Statistics Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Total Passengers',
                value: totalPassengers.toString(),
                icon: Icons.people,
              ),
              _StatItem(
                label: 'Checked In',
                value: checkedInCount.toString(),
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
        // Passengers List
        Expanded(
          child: passengers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'No passengers yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: passengers.length,
                  itemBuilder: (context, index) {
                    final passenger = passengers[index] as Map<String, dynamic>;
                    return _PassengerCard(
                      passenger: passenger,
                      onReassignSeat: () => _reassignSeat(
                        passenger['ticket_id'],
                        passenger['seat']?['id'],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE94560), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PassengerCard extends StatelessWidget {
  final Map<String, dynamic> passenger;
  final VoidCallback onReassignSeat;

  const _PassengerCard({
    required this.passenger,
    required this.onReassignSeat,
  });

  @override
  Widget build(BuildContext context) {
    final seat = passenger['seat'] as Map<String, dynamic>?;
    final seatInfo = seat != null
        ? '${seat['row']}${seat['letter']} (${seat['class']})'
        : 'No seat assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
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
                      passenger['passenger_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ticket: ${passenger['ticket_number']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: passenger['booking_status'] == 'checked_in'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  passenger['booking_status'] == 'checked_in' ? 'CHECKED IN' : 'PAID',
                  style: TextStyle(
                    color: passenger['booking_status'] == 'checked_in'
                        ? Colors.green
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (passenger['passenger_phone'] != null) ...[
            _InfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: passenger['passenger_phone'],
            ),
            const SizedBox(height: 8),
          ],
          if (passenger['passenger_passport'] != null) ...[
            _InfoRow(
              icon: Icons.credit_card,
              label: 'Passport',
              value: passenger['passenger_passport'],
            ),
            const SizedBox(height: 8),
          ],
          if (passenger['passenger_nationality'] != null) ...[
            _InfoRow(
              icon: Icons.flag,
              label: 'Nationality',
              value: passenger['passenger_nationality'],
            ),
            const SizedBox(height: 8),
          ],
          _InfoRow(
            icon: Icons.event_seat,
            label: 'Seat',
            value: seatInfo,
          ),
          const SizedBox(height: 12),
          if (seat != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReassignSeat,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Reassign Seat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE94560)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}

class _SeatSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> seats;

  const _SeatSelectionDialog({required this.seats});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select New Seat'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: seats.length,
          itemBuilder: (context, index) {
            final seat = seats[index];
            return ListTile(
              title: Text('${seat['row_number']}${seat['seat_letter']}'),
              subtitle: Text(seat['seat_class']),
              onTap: () => Navigator.pop(context, seat),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

