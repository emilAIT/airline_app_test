// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Load announcements for user's booked flights using new endpoint
    final announcements = await ApiService.getMyAnnouncements();

    // Sort by created_at (newest first)
    announcements.sort(
      (a, b) => (b['created_at'] ?? '').toString().compareTo(
        (a['created_at'] ?? '').toString(),
      ),
    );

    if (!mounted) return;
    setState(() {
      _items = announcements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Announcements',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
                ? Center(
                    child: Text(
                      'Нет объявлений',
                      style: GoogleFonts.montserrat(),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final a = _items[index];
                      final msg = a['message']?.toString() ?? '';
                      final type = a['announcement_type']?.toString() ?? '';
                      final flightId = a['flight_id']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ZaKuColors.gold.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flight $flightId',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (type.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  type,
                                  style: GoogleFonts.montserrat(
                                    color: ZaKuColors.darkGrey.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            if (msg.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(msg, style: GoogleFonts.montserrat()),
                            ],
                          ],
                        ),
                      );
                    },
                  )),
    );
  }
}
