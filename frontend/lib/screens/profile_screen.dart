// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/zaku_colors.dart';
import 'auth_screen.dart';
import 'profile_edit_screen.dart';
import 'staff_airplanes_screen.dart';
import 'staff_announcements_screen.dart';
import 'staff_bookings_screen.dart';
import 'staff_flights_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onAuthChanged;
  const ProfileScreen({super.key, required this.onAuthChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthService.isAuthenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await ApiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AuthService.isAuthenticated;
    final isStaff = AuthService.isStaff;
    final user = AuthService.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Профиль',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
        actions: [
          if (isAuth)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                AuthService.logout();
                widget.onAuthChanged();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ZaKuColors.gold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStaff
                      ? Icons.admin_panel_settings
                      : (isAuth ? Icons.person : Icons.person_outline),
                  size: 50,
                  color: ZaKuColors.burgundy,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAuth ? (user?['email'] ?? 'Пользователь') : 'Гость',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ZaKuColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAuth
                  ? (isStaff ? 'Администратор (STAFF)' : 'Пассажир')
                  : 'Войдите для доступа к функциям',
              style: GoogleFonts.montserrat(
                color: ZaKuColors.darkGrey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            if (!isAuth)
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                  if (result == true) widget.onAuthChanged();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZaKuColors.gold,
                  foregroundColor: ZaKuColors.burgundy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Войти / Регистрация',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                ),
              ),
            if (isAuth && isStaff)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Панель управления',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ZaKuColors.burgundy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStaffTile(
                      Icons.flight,
                      'Управление рейсами',
                      'Редактирование расписания',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffFlightsScreen(),
                        ),
                      ),
                    ),
                    _buildStaffTile(
                      Icons.airplanemode_active,
                      'Управление самолетами',
                      'Добавление и аудит флота',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffAirplanesScreen(),
                        ),
                      ),
                    ),
                    _buildStaffTile(
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
                    _buildStaffTile(
                      Icons.event_seat,
                      'Управление бронями',
                      'Работа с билетами и местами',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffBookingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isAuth && !isStaff) _buildPassengerProfile(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger Profile',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ZaKuColors.burgundy,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: GoogleFonts.montserrat(color: Colors.red))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ZaKuColors.gold.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('First name', _profile?['first_name']),
                  _kv('Last name', _profile?['last_name']),
                  _kv('Passport', _profile?['passport_number']),
                  _kv('Nationality', _profile?['nationality']),
                  _kv('DOB', _profile?['date_of_birth']),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final saved = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
              if (saved == true) {
                await _load();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ZaKuColors.gold,
              foregroundColor: ZaKuColors.burgundy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit),
            label: Text(
              'Edit profile',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              AuthService.logout();
              widget.onAuthChanged();
            },
            icon: const Icon(Icons.logout),
            label: Text(
              'Logout',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTile(
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

  Widget _kv(String k, dynamic v) {
    final value = (v ?? '').toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: ZaKuColors.darkGrey.withOpacity(0.75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.montserrat(),
            ),
          ),
        ],
      ),
    );
  }
}
