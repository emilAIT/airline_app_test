import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/announcements_provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  var _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final flightId = ModalRoute.of(context)?.settings.arguments as int?;
      // Prevent setState during build and infinite loops
      Future.microtask(() {
        context.read<AnnouncementsProvider>().load(flightId);
      });
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.announcements.isEmpty
              ? const Center(child: Text('No announcements'))
              : ListView.builder(
                  itemCount: provider.announcements.length,
                  itemBuilder: (_, i) {
                    final a = provider.announcements[i];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text(a.message),
                        trailing: Text(a.type),
                      ),
                    );
                  },
                ),
    );
  }
}