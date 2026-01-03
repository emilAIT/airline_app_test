import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../theme/app_theme.dart';
import 'create_announcement_screen.dart';

class StaffAnnouncementsScreen extends StatefulWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  State<StaffAnnouncementsScreen> createState() =>
      _StaffAnnouncementsScreenState();
}

class _StaffAnnouncementsScreenState extends State<StaffAnnouncementsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _announcements = [];
  List<dynamic> _flights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final announcements = await _api.getStaffAnnouncements();
      final flights = await _api.getStaffFlights();
      setState(() {
        _announcements = announcements;
        _flights = flights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
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
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                        'Manage Announcements',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: EldiyarTheme.textPrimary,
                        ),
                      ),
                    ),
                    GlowButton(
                      label: 'Create',
                      icon: Icons.add,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateAnnouncementScreen(flights: _flights),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Announcements List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EldiyarTheme.primaryBlue,
                          ),
                        ),
                      )
                    : _announcements.isEmpty
                    ? const Center(
                        child: Text(
                          'No announcements',
                          style: TextStyle(color: EldiyarTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            final createdAt = DateTime.parse(
                              announcement['created_at'],
                            );
                            final type = announcement['type'];

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(
                                            type,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getTypeColor(
                                              type,
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Icon(
                                          _getTypeIcon(type),
                                          color: _getTypeColor(type),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              announcement['title'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: EldiyarTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              type,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _getTypeColor(type),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    announcement['message'],
                                    style: const TextStyle(
                                      color: EldiyarTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (announcement['flight'] != null)
                                        Text(
                                          'Flight: ${announcement['flight']['flight_number']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: EldiyarTheme.textSecondary,
                                          ),
                                        ),
                                      Text(
                                        DateFormat(
                                          'MMM dd, yyyy HH:mm',
                                        ).format(createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: EldiyarTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'DELAY':
        return Colors.orange;
      case 'CANCELLATION':
        return EldiyarTheme.errorRed;
      case 'GATE_CHANGE':
        return EldiyarTheme.primaryBlue;
      case 'BOARDING_STARTED':
        return EldiyarTheme.successGreen;
      default:
        return EldiyarTheme.accentTeal;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'DELAY':
        return Icons.schedule;
      case 'CANCELLATION':
        return Icons.cancel;
      case 'GATE_CHANGE':
        return Icons.directions_walk;
      case 'BOARDING_STARTED':
        return Icons.flight_takeoff;
      default:
        return Icons.info;
    }
  }
}
