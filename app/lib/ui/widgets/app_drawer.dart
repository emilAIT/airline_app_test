import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../views/admin_flights/admin_flights_view.dart';
import '../views/admin_airplanes/admin_airplanes_view.dart';
import '../views/admin_airports/admin_airports_view.dart';
import '../views/admin_users/admin_users_view.dart';
import '../views/admin_bookings/admin_bookings_view.dart';
import '../views/admin_payments/admin_payments_view.dart';
import '../views/admin_tickets/admin_tickets_view.dart';
import '../views/admin_announcements/admin_announcements_view.dart';

class AppDrawer extends StatelessWidget {
  final UserPublic? currentUser;
  final VoidCallback? onLogout;

  const AppDrawer({
    Key? key,
    this.currentUser,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isStaff = currentUser?.role == UserRole.staff;
    final authService = locator<AuthService>();
    final navigationService = locator<NavigationService>();

    return Drawer(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.dark800,
          border: Border(
            right: BorderSide(color: AppTheme.dark600, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Netflix-style header with gradient
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: AppTheme.getPinkGradient(),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isStaff ? Icons.admin_panel_settings : Icons.person,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUser?.fullName ?? currentUser?.email ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isStaff ? 'STAFF' : 'PASSENGER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Main section
                  _buildSectionHeader('MAIN'),
                  _buildMenuItem(
                    context,
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Search Flights',
                    onTap: () {
                      Navigator.pop(context);
                      navigationService.replaceWith(Routes.flightSearchView);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.confirmation_number_rounded,
                    title: 'My Bookings',
                    onTap: () {
                      Navigator.pop(context);
                      navigationService.navigateTo(Routes.myBookingsView);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      navigationService.navigateTo(Routes.profileView);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.campaign_rounded,
                    title: 'Announcements',
                    onTap: () {
                      Navigator.pop(context);
                      if (isStaff) {
                        // Admin goes to AdminAnnouncementsView
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAnnouncementsView(),
                          ),
                        );
                      } else {
                        // Passenger goes to AnnouncementsView
                        navigationService.navigateTo(Routes.announcementsView);
                      }
                    },
                  ),
                  
                  // Staff only sections
                  if (isStaff) ...[
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.dark600),
                    const SizedBox(height: 8),
                    _buildSectionHeader('ADMIN PANEL'),
                    _buildMenuItem(
                      context,
                      icon: Icons.flight_rounded,
                      title: 'Flights',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminFlightsView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.airplanemode_active_rounded,
                      title: 'Airplanes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAirplanesView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.airport_shuttle_rounded,
                      title: 'Airports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAirportsView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.people_rounded,
                      title: 'Users',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUsersView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.confirmation_number_rounded,
                      title: 'Bookings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminBookingsView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.payment_rounded,
                      title: 'Payments',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPaymentsView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.confirmation_number_rounded,
                      title: 'Tickets',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminTicketsView(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Manage Announcements',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAnnouncementsView(),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.dark600),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onLogout?.call();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.neutral500,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppTheme.error.withOpacity(0.2)
                        : AppTheme.pink600.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? AppTheme.error : AppTheme.pink600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppTheme.error : Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.neutral500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
