import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/announcement_item.dart';
import '../theme/app_theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await _api.getAnnouncements();
      // Sort logic: HIGH > MEDIUM > LOW, then by Date (Newest first)
      announcements.sort((a, b) {
        final priorityA = _getPriorityScore(a['priority']);
        final priorityB = _getPriorityScore(b['priority']);
        
        if (priorityA != priorityB) {
          return priorityB.compareTo(priorityA); // Descending priority
        }
        
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA); // Newest first
      });

      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: $e'),
            backgroundColor: EldiyarTheme.errorRed,
          ),
        );
      }
    }
  }

  int _getPriorityScore(String? priority) {
    switch (priority) {
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      case 'LOW':
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EldiyarTheme.darkerBackground,
      appBar: AppBar(
        title: const Text('CONTROL CENTER'),
        centerTitle: true,
        backgroundColor: EldiyarTheme.darkBackground.withOpacity(0.8),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(EldiyarTheme.primaryBlue),
              ),
            )
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: EldiyarTheme.primaryBlue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All Systems Nominal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: EldiyarTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: EldiyarTheme.primaryBlue,
                  backgroundColor: EldiyarTheme.cardBackground,
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      return AnnouncementItem(
                        announcement: _announcements[index],
                      );
                    },
                  ),
                ),
    );
  }
}

