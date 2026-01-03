import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'boarding_pass_screen.dart';

class CheckInScreen extends StatefulWidget {
  final int ticketId;

  const CheckInScreen({super.key, required this.ticketId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final ApiService _api = ApiService();
  bool _isCheckingIn = false;

  Future<void> _checkIn() async {
    setState(() => _isCheckingIn = true);
    try {
      await _api.checkIn(widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BoardingPassScreen(ticketId: widget.ticketId),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingIn = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Check In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete check-in to receive your boarding pass',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isCheckingIn ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: _isCheckingIn
                    ? const CircularProgressIndicator()
                    : const Text('Check In Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

