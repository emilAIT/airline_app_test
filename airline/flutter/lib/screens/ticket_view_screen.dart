import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TicketViewScreen extends StatefulWidget {
  final int ticketId;

  const TicketViewScreen({super.key, required this.ticketId});

  @override
  State<TicketViewScreen> createState() => _TicketViewScreenState();
}

class _TicketViewScreenState extends State<TicketViewScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _ticket;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadTicket();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await _api.getTicket(widget.ticketId);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ticket: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  String _generateTicketData() {
    if (_ticket == null) return '';
    return '${_ticket!['ticket_number']}|${_ticket!['flight']['flight_number']}|${_ticket!['passenger_name']}|${_ticket!['seat_number']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EldiyarTheme.darkerBackground,
              EldiyarTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      EldiyarTheme.primaryBlue,
                    ),
                  ),
                )
              : _ticket == null
              ? Center(
                  child: Text(
                    'Ticket not found',
                    style: TextStyle(color: EldiyarTheme.textPrimary),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: EldiyarTheme.primaryBlue,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          EldiyarTheme.primaryBlue,
                                          EldiyarTheme.accentTeal,
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'ELDIK AirLines',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Ticket Card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                EldiyarTheme.cardBackground,
                                EldiyarTheme.cardBackground.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: EldiyarTheme.primaryBlue.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EldiyarTheme.primaryBlue.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Ticket Header
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      EldiyarTheme.primaryBlue,
                                      EldiyarTheme.accentTeal,
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _ticket!['flight']['origin']['code'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            Text(
                                              _ticket!['flight']['origin']['city'],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.flight_takeoff,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _ticket!['flight']['flight_number'] ??
                                                  'N/A',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _ticket!['flight']['destination']['code'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            Text(
                                              _ticket!['flight']['destination']['city'] ??
                                                  'N/A',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Ticket Body
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Passenger Info
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoRow(
                                            'Passenger',
                                            _ticket!['passenger_name'] ?? 'N/A',
                                            Icons.person,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildInfoRow(
                                            'Seat',
                                            _ticket!['seat_number'] ?? 'N/A',
                                            Icons.event_seat,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Flight Details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoRow(
                                            'Date',
                                            DateFormat('MMM dd, yyyy').format(
                                              DateTime.parse(
                                                _ticket!['flight']['departure_time'] ??
                                                    DateTime.now().toString(),
                                              ),
                                            ),
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildInfoRow(
                                            'Time',
                                            DateFormat('HH:mm').format(
                                              DateTime.parse(
                                                _ticket!['flight']['departure_time'] ??
                                                    DateTime.now().toString(),
                                              ),
                                            ),
                                            Icons.access_time,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Ticket Number
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: EldiyarTheme.primaryBlue
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: EldiyarTheme.primaryBlue
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.confirmation_number,
                                            color: EldiyarTheme.primaryBlue,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ticket: ${_ticket!['ticket_number'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              color: EldiyarTheme.primaryBlue,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // QR Code
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: EldiyarTheme.primaryBlue
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          QrImageView(
                                            data: _generateTicketData(),
                                            version: QrVersions.auto,
                                            size: 200,
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Scan for check-in',
                                            style: TextStyle(
                                              color: EldiyarTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Barcode
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: BarcodeWidget(
                                        barcode: Barcode.code128(),
                                        data: _ticket!['ticket_number'] ?? '',
                                        width: double.infinity,
                                        height: 80,
                                        drawText: false,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _ticket!['ticket_number'] ?? '',
                                      style: TextStyle(
                                        color: EldiyarTheme.textSecondary,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EldiyarTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EldiyarTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: EldiyarTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: EldiyarTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: EldiyarTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
