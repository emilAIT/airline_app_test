import 'dart:async';
import 'package:stacked/stacked.dart';
import '../../../services/announcement_service.dart';
import '../../../models/announcement_model.dart';

class AnnouncementsViewModel extends BaseViewModel {
  final AnnouncementService _announcementService = AnnouncementService();

  List<AnnouncementPublic> _announcements = [];
  List<AnnouncementPublic> get announcements => _announcements;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Timer? _refreshTimer;

  Future<void> loadAnnouncements() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await _announcementService.getMyAnnouncements();
      // Sort by created_at descending (newest first)
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _announcements = [];
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
}

