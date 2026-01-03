import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/announcement_service.dart';
import '../../../models/announcement_model.dart';

class CreateAnnouncementViewModel extends BaseViewModel {
  final AnnouncementService _announcementService = AnnouncementService();
  final NavigationService _navigationService = locator<NavigationService>();

  final formKey = GlobalKey<FormState>();
  final flightIdController = TextEditingController();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  AnnouncementType type = AnnouncementType.general;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> createAnnouncement() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final announcementCreate = AnnouncementCreate(
        flightId: flightIdController.text.trim(),
        type: type,
        title: titleController.text.trim(),
        message: messageController.text.trim(),
      );

      await _announcementService.createAnnouncement(announcementCreate);

      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
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

