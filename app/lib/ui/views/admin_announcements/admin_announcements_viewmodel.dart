import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/announcement_service.dart';
import '../../../models/announcement_model.dart';
import '../create_announcement/create_announcement_view.dart';
import '../update_announcement/update_announcement_view.dart';

class AdminAnnouncementsViewModel extends BaseViewModel {
  final AnnouncementService _announcementService = AnnouncementService();
  Timer? _refreshTimer;
  final NavigationService _navigationService = locator<NavigationService>();

  List<AnnouncementPublic> _announcements = [];
  List<AnnouncementPublic> get announcements => _announcements;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadAnnouncements() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      print('AdminAnnouncementsViewModel: Loading all announcements...');
      // AdminAnnouncementsView используется только для admin
      // Используем getAllAnnouncements для получения всех announcements
      final loaded = await _announcementService.getAllAnnouncements();
      print('AdminAnnouncementsViewModel: Loaded ${loaded.length} announcements');
      
      // Always set announcements, even if empty
      _announcements = loaded;
      
      // Sort by created_at descending (newest first)
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Clear error if we got here successfully
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('AdminAnnouncementsViewModel: Error loading announcements: $e');
      // Only set error if it's a real error, not just empty list
      final errorStr = e.toString().replaceAll('Exception: ', '');
      if (errorStr.contains('Failed to get all announcements') || 
          errorStr.contains('Get all announcements error')) {
        _errorMessage = errorStr;
      } else {
        // For other errors, just show empty list
        _announcements = [];
        _errorMessage = null;
      }
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void startAutoRefresh() {
    // Cancel existing timer if any
    _refreshTimer?.cancel();
    
    // Start new timer that refreshes every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadAnnouncements();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  void navigateToCreateAnnouncement() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAnnouncementView(),
        ),
      ).then((_) => loadAnnouncements());
    }
  }

  void navigateToUpdateAnnouncement(AnnouncementPublic announcement) {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateAnnouncementView(
            args: UpdateAnnouncementViewArguments(announcement: announcement),
          ),
        ),
      ).then((_) => loadAnnouncements());
    }
  }

  void showDeleteDialog(BuildContext context, AnnouncementPublic announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete announcement "${announcement.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteAnnouncement(announcement.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    setBusy(true);
    try {
      await _announcementService.deleteAnnouncement(announcementId);
      await loadAnnouncements();
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      }
    } catch (e) {
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }
}

