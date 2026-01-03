import 'package:flutter/material.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  String type = 'GENERAL';

  final List<Map<String, String>> announcements = [];

  void createAnnouncement() {
    setState(() {
      announcements.add({
        'title': titleCtrl.text,
        'message': messageCtrl.text,
        'type': type,
      });
    });
    titleCtrl.clear();
    messageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                DropdownMenuItem(value: 'DELAY', child: Text('Delay')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                DropdownMenuItem(value: 'GATE_CHANGE', child: Text('Gate Change')),
              ],
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: createAnnouncement,
              child: const Text('Publish'),
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (_, i) {
                  final a = announcements[i];
                  return ListTile(
                    title: Text(a['title']!),
                    subtitle: Text(a['message']!),
                    trailing: Text(a['type']!),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}