import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class BoardingPassScreen extends StatefulWidget {
  final int ticketId;

  const BoardingPassScreen({super.key, required this.ticketId});

  @override
  State<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends State<BoardingPassScreen> {
  dynamic _boardingPass;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBoardingPass();
  }

  Future<void> _loadBoardingPass() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getBoardingPass(widget.ticketId);

      if (mounted) {
        setState(() {
          _boardingPass = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load boarding pass';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boarding Pass')),
        body: const LoadingWidget(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boarding Pass')),
        body: ErrorDisplayWidget(
          message: _errorMessage!,
          onRetry: _loadBoardingPass,
        ),
      );
    }

    if (_boardingPass == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boarding Pass')),
        body: const Center(child: Text('Boarding pass not found')),
      );
    }

    final boardingTime = DateTime.parse(_boardingPass['boarding_time']).toLocal();
    final departureTime = DateTime.parse(_boardingPass['departure_time']).toLocal();
    final arrivalTime = DateTime.parse(_boardingPass['arrival_time']).toLocal();
    
    // Decode the base64 QR code image
    final qrCodeBase64 = _boardingPass['qr_code'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Boarding Pass')),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Header with airline branding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.flight, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'BOARDING PASS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passenger Name
                    Text(
                      _boardingPass['passenger_name'].toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passenger',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Flight Route - From -> To
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _boardingPass['departure_airport_code'],
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _boardingPass['departure_airport_name'],
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.flight_takeoff,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _boardingPass['arrival_airport_code'],
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _boardingPass['arrival_airport_name'],
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Departure & Arrival Times
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'DEPARTURE',
                            DateFormat('HH:mm').format(departureTime),
                            DateFormat('MMM dd, yyyy').format(departureTime),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'ARRIVAL',
                            DateFormat('HH:mm').format(arrivalTime),
                            DateFormat('MMM dd, yyyy').format(arrivalTime),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Flight Details Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(context, 'Flight', _boardingPass['flight_number']),
                        ),
                        Expanded(
                          child: _buildDetailItem(context, 'Seat', _boardingPass['seat'] ?? 'TBA'),
                        ),
                        Expanded(
                          child: _buildDetailItem(context, 'Gate', _boardingPass['gate'] ?? 'TBA'),
                        ),
                        if (_boardingPass['terminal'] != null)
                          Expanded(
                            child: _buildDetailItem(context, 'Terminal', _boardingPass['terminal']),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Boarding Time Highlight
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'BOARDING TIME',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(boardingTime),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(boardingTime),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Boarding starts 1 hour before departure.',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[900]),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // QR Code
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.memory(
                              base64Decode(qrCodeBase64),
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scan at the gate',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String time, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

