import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final user = auth.user;
          
          return Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 24,
                  left: 24,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1556382363-8967ac2b3543'), 
                    fit: BoxFit.cover,
                    opacity: 0.2, // Subtle background texture
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: theme.primaryColor,
                        child: Text(
                          user != null ? user.email[0].toUpperCase() : 'G',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user != null ? 'Welcome Back,' : 'Welcome to SkyFlow',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null ? user.email : 'Guest User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // MENU ITEMS
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/');
                      },
                    ),

                    if (!auth.isAuthenticated) ...[
                      const Divider(),
                      _DrawerItem(
                        icon: Icons.login_rounded,
                        title: 'Sign In',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.person_add_rounded,
                        title: 'Register',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/register');
                        },
                      ),
                    ],

                    if (auth.isAuthenticated) ...[
                      const Divider(),
                      if (user?.role == UserRole.passenger) ...[
                        _DrawerItem(
                          icon: Icons.person_rounded,
                          title: 'My Profile',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/profile_update');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.notifications_active_rounded,
                          title: 'Announcements',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/announcements');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.confirmation_number_rounded,
                          title: 'My Trips',
                          onTap: () {
                             Navigator.pop(context);
                             Navigator.pushNamed(context, '/my_trips');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.flight_rounded,
                          title: 'All Flights',
                          onTap: () {
                             Navigator.pop(context);
                             Navigator.pushNamed(context, '/all_flights');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.location_on_rounded,
                          title: 'Airports',
                          onTap: () {
                             Navigator.pop(context);
                             Navigator.pushNamed(context, '/airports');
                          },
                        ), 
                      ],
                      
                      if (user?.role == UserRole.staff) ...[
                         _DrawerItem(
                          icon: Icons.dashboard_rounded,
                          title: 'Staff Dashboard',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff_dashboard');
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // FOOTER
              if (auth.isAuthenticated)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      auth.logout();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                    label: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Theme.of(context).primaryColor.withOpacity(0.05),
    );
  }
}
