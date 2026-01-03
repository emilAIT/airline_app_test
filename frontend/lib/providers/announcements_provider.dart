import 'package:flutter/material.dart';
import '../core/api/announcements_api.dart';
import '../models/announcement.dart';

class AnnouncementsProvider extends ChangeNotifier {
  List<Announcement> announcements = [];
  bool loading = false;

  Future<void> load(int? flightId) async {
    loading = true;
    notifyListeners();

    try {
      if (flightId != null) {
        announcements = await AnnouncementsApi.byFlight(flightId);
      } else {
        announcements = await AnnouncementsApi.getGlobal();
      }
    } catch (e) {
      print("Error loading announcements: $e");
      announcements = [];
    }

    loading = false;
    notifyListeners();
  }
}