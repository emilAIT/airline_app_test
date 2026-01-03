import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/announcement_service.dart';
import '../../../models/announcement_model.dart';

class UpdateAnnouncementViewModel extends BaseViewModel {
  final AnnouncementService _announcementService = AnnouncementService();
  final NavigationService _navigationService = locator<NavigationService>();
  final AnnouncementPublic announcement;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  AnnouncementType type = AnnouncementType.general;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UpdateAnnouncementViewModel({required this.announcement}) {
    titleController.text = announcement.title;
    messageController.text = announcement.message;
    type = announcement.type;
  }

  Future<void> updateAnnouncement() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final update = AnnouncementUpdate(
        type: type,
        title: titleController.text.trim().isEmpty ? null : titleController.text.trim(),
        message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      );

      await _announcementService.updateAnnouncement(announcement.id, update);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}

