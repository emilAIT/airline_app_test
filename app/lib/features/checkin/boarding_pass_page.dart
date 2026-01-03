import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/checkin_api.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/models/boarding_pass.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/formatters.dart';

class BoardingPassPage extends StatefulWidget {
  final int ticketId;

  const BoardingPassPage({super.key, required this.ticketId});

  @override
  State<BoardingPassPage> createState() => _BoardingPassPageState();
}

class _BoardingPassPageState extends State<BoardingPassPage> {
  late final ApiClient _apiClient;
  late final CheckinApi _checkinApi;
  BoardingPass? _boardingPass;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiClient = ApiClient(
      baseUrl: AppConstants.baseUrl,
      authService: authService,
    );
    _checkinApi = CheckinApi(_apiClient);
    _loadBoardingPass();
  }

  Future<void> _loadBoardingPass() async {
    try {
      final boardingPass = await _checkinApi.getBoardingPass(widget.ticketId);
      setState(() {
        _boardingPass = boardingPass;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boarding Pass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screenshot this pass to save it')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadBoardingPass)
              : _boardingPass == null
                  ? const Center(child: Text('No boarding pass found'))
                  : _buildBoardingPass(),
    );
  }

  Widget _buildBoardingPass() {
    final pass = _boardingPass!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flight_takeoff,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'BOARDING PASS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Passenger Info
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        pass.passengerName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Flight Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfo('Flight', pass.flightNumber),
                          _buildInfo('Seat', pass.seatNumber),
                          _buildInfo('Gate', pass.gate ?? 'TBA'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfo(
                            'Boarding Time',
                            pass.boardingTime != null ? Formatters.formatTime(pass.boardingTime!) : 'TBA',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: pass.qrCode,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan at gate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Arrive at the gate at least 30 minutes before boarding time\n'
                  '• Have your boarding pass ready at security and gate\n'
                  '• Check your carry-on baggage allowance',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
