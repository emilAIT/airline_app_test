// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'staff_airplanes_screen.dart';
import 'staff_announcements_screen.dart';
import 'staff_bookings_screen.dart';
import 'staff_flights_screen.dart';
import '../theme/zaku_colors.dart';

class StaffDashboardScreen extends StatelessWidget {
  final VoidCallback onAuthChanged;

  const StaffDashboardScreen({super.key, required this.onAuthChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Панель персонала',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.logout();
              onAuthChanged();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Панель управления',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ZaKuColors.burgundy,
              ),
            ),
            const SizedBox(height: 24),
            _buildTile(
              Icons.flight,
              'Управление рейсами',
              'Создание и изменение расписания',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffFlightsScreen()),
              ),
            ),
            _buildTile(
              Icons.airplanemode_active,
              'Управление самолетами',
              'Добавление и аудит флота',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffAirplanesScreen()),
              ),
            ),
            _buildTile(
              Icons.campaign,
              'Публикация объявлений',
              'Информирование пассажиров',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffAnnouncementsScreen(),
                ),
              ),
            ),
            _buildTile(
              Icons.event_seat,
              'Управление бронями',
              'Работа с билетами и местами',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffBookingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZaKuColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ZaKuColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ZaKuColors.burgundy),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: ZaKuColors.darkGrey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ZaKuColors.gold),
          ],
        ),
      ),
    );
  }
}
