import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BoardingPassScreen extends StatefulWidget {
  final int ticketId;

  const BoardingPassScreen({super.key, required this.ticketId});

  @override
  State<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends State<BoardingPassScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _boardingPass;
  bool _isLoading = true;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadBoardingPass();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadBoardingPass() async {
    try {
      final boardingPass = await _api.getBoardingPass(widget.ticketId);
      setState(() {
        _boardingPass = boardingPass;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading boarding pass: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                EldiyarTheme.primaryBlue,
              ),
            ),
          ),
        ),
      );
    }

    if (_boardingPass == null) {
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
          child: const Center(
            child: Text(
              'Boarding pass not found',
              style: TextStyle(color: EldiyarTheme.textPrimary),
            ),
          ),
        ),
      );
    }

    final boardingTime = _boardingPass!['boarding_time'] != null
        ? DateTime.parse(_boardingPass!['boarding_time'])
        : null;

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
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                      const Expanded(
                        child: Text(
                          'Boarding Pass',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: EldiyarTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Boarding Pass Card
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
                        color: EldiyarTheme.primaryBlue.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EldiyarTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Airline Logo
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                EldiyarTheme.primaryBlue,
                                EldiyarTheme.accentTeal,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'ELDIK AirLines',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'DIGITAL BOARDING PASS',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: EldiyarTheme.textSecondary,
                            ),
                          ),
                          const Divider(
                            color: EldiyarTheme.primaryBlue,
                            thickness: 1,
                            height: 32,
                          ),
                          // Flight Number
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: EldiyarTheme.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EldiyarTheme.primaryBlue.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              _boardingPass!['flight_number'],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: EldiyarTheme.primaryBlue,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Passenger Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PASSENGER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      color: EldiyarTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _boardingPass!['passenger_name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: EldiyarTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'SEAT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      color: EldiyarTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EldiyarTheme.accentTeal
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: EldiyarTheme.accentTeal
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      _boardingPass!['seat'],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: EldiyarTheme.accentTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_boardingPass!['gate'] != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: EldiyarTheme.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EldiyarTheme.secondaryPurple
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: EldiyarTheme.secondaryPurple
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _boardingPass!['gate'],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: EldiyarTheme.secondaryPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (boardingTime != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'BOARDING TIME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: EldiyarTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(boardingTime),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: EldiyarTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          const Divider(
                            color: EldiyarTheme.primaryBlue,
                            thickness: 1,
                            height: 32,
                          ),
                          // QR Code
                          if (_boardingPass!['qr_code'] != null) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: EldiyarTheme.primaryBlue.withOpacity(
                                    0.5,
                                  ),
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
                                  QrImageView(
                                    data: _boardingPass!['qr_code'],
                                    version: QrVersions.auto,
                                    size: 200,
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Scan for boarding',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                              data: _boardingPass!['ticket_number'] ?? '',
                              width: double.infinity,
                              height: 80,
                              drawText: false,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _boardingPass!['ticket_number'] ?? '',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
