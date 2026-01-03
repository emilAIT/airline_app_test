import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import 'boarding_pass_screen.dart';

class CheckInScreen extends StatefulWidget {
  final int ticketId;

  const CheckInScreen({super.key, required this.ticketId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.checkIn(widget.ticketId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BoardingPassScreen(ticketId: widget.ticketId),
          ),
          result: true,
        );
      }
    } catch (e) {
      if (mounted) {
        String detail = 'Check-in failed. Please try again.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('detail')) {
            detail = data['detail'];
          }
        }
        setState(() {
          _errorMessage = detail;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.flight_takeoff, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Ready to Check In?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Online check-in opens 24 hours and closes 1 hour before departure. Complete it now to get your boarding pass.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const LoadingWidget()
            else
              ElevatedButton.icon(
                onPressed: _checkIn,
                icon: const Icon(Icons.check_circle),
                label: const Text('Check In'),
              ),
          ],
        ),
      ),
    );
  }
}

