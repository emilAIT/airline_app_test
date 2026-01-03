import 'package:flutter/material.dart';

class EditAnnouncementPage extends StatelessWidget {
  final int announcementId;

  const EditAnnouncementPage({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Announcement')),
      body: const Center(child: Text('Edit form - similar to create')),
    );
  }
}
