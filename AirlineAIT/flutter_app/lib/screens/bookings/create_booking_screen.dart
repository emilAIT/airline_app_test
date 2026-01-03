import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../payment/payment_screen.dart';
import '../flights/seat_selection_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final int flightId;

  const CreateBookingScreen({super.key, required this.flightId});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  List<dynamic> _passengers = [];
  final List<Map<String, dynamic>> _selectedPassengers = [];
  final Map<int, Map<String, dynamic>> _passengerSeats = {}; // passenger_id -> {seat_number, price}
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getProfiles();

      if (mounted) {
        setState(() {
          _passengers = response.data;
          _isLoading = false;
        });
        if (_passengers.isEmpty) {
          setState(() {
            _errorMessage = 'No passenger profiles found. Please add profiles in the Profile section.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load passenger profiles';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSeats() async {
    if (_selectedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one passenger first')),
      );
      return;
    }

    final Map<int, Map<String, dynamic>>? result = await Navigator.of(context).push<Map<int, Map<String, dynamic>>>(
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          flightId: widget.flightId,
          passengers: _selectedPassengers,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _passengerSeats.clear();
        _passengerSeats.addAll(result);
      });
    }
  }

  Future<void> _createBooking() async {
    if (_selectedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one passenger')));
      return;
    }

    bool allHaveSeats = _selectedPassengers.every((p) => _passengerSeats[p['id']] != null);
    if (!allHaveSeats) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select seats for all passengers')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final bookingData = {
        'flight_id': widget.flightId,
        'passengers': _selectedPassengers.map((p) => {
              'passenger_profile_id': p['id'],
              'seat_number': _passengerSeats[p['id']]?['seat_number'],
            }).toList(),
      };

      final response = await apiService.createBooking(bookingData);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Success!'),
              ],
            ),
            content: const Text('Your booking has been created successfully. Your seat(s) are reserved for 10 minutes. Please proceed to pay in the "Bookings" section to confirm your trip.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create booking';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Booking')),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    _buildErrorCard(),
                  
                  _buildSectionHeader(Icons.person, 'Step 1: Select Profiles'),
                  const SizedBox(height: 12),
                  ..._passengers.map((p) => _buildPassengerTile(p)),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader(Icons.chair, 'Step 2: Choose Seats'),
                  const SizedBox(height: 16),
                  _buildSeatSelectionSummary(),
                  
                  const SizedBox(height: 48),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPassengerTile(dynamic passenger) {
    final isSelected = _selectedPassengers.any((p) => p['id'] == passenger['id']);
    return CheckboxListTile(
      title: Text(passenger['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('Passport: ${passenger['passport_number'] ?? 'N/A'}'),
      value: isSelected,
      activeColor: Theme.of(context).primaryColor,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedPassengers.add(passenger);
          } else {
            _selectedPassengers.removeWhere((p) => p['id'] == passenger['id']);
            _passengerSeats.remove(passenger['id']);
          }
        });
      },
    );
  }

  Widget _buildSeatSelectionSummary() {
    if (_selectedPassengers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text('Select passengers above to choose seats', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        ..._selectedPassengers.map((p) {
          final seatData = _passengerSeats[p['id']];
          final seatNumber = seatData?['seat_number'];
          final seatPrice = seatData?['price'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: seatNumber != null ? Colors.green.shade200 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: seatNumber != null ? Colors.green.shade50 : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (seatNumber != null)
                      Text('Seat: $seatNumber', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      seatNumber ?? 'No seat selected',
                      style: TextStyle(color: seatNumber != null ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                    if (seatPrice != null)
                      Text('\$${seatPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        }),
        if (_passengerSeats.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Booking Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '\$${_passengerSeats.values.fold(0.0, (sum, item) => sum + (item['price'] ?? 0)).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectSeats,
          icon: const Icon(Icons.map),
          label: const Text('Open Seat Map'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade700,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canBook = _selectedPassengers.isNotEmpty && _selectedPassengers.every((p) => _passengerSeats[p['id']] != null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: canBook ? _createBooking : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirm & Book Flight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

