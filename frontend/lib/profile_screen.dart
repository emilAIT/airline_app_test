import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flight_search_screen.dart'; // Import FlightSearchScreen
import 'services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _profile = {};
  bool _notifications = true;
  String _language = 'English';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ffController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = StorageService().getProfile() ?? {
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+90 555 123 4567',
      'frequentFlyer': 'TK 123456789',
      'miles': '24,500',
      'status': 'Classic Member',
      'language': 'English',
      'notifications': true,
    };
    
    setState(() {
      _profile = profile;
      _notifications = profile['notifications'] ?? true;
      _language = profile['language'] ?? 'English';
      
      _nameController.text = profile['name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _ffController.text = profile['frequentFlyer'] ?? '';
    });
  }

  Future<void> _saveProfile({bool showSnack = true}) async {
    final newProfile = {
      ..._profile,
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'frequentFlyer': _ffController.text,
      'language': _language,
      'notifications': _notifications,
    };
    
    await StorageService().saveProfile(newProfile);
    setState(() {
      _profile = newProfile;
    });
    
    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  // A) Edit Profile Dialog
  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveProfile();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B1E3B), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('SAVE CHANGES'),
            ),
          ],
        ),
      ),
    );
  }

  // B) Frequent Flyer Dialog
  void _showFrequentFlyerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Frequent Flyer', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _ffController,
          decoration: const InputDecoration(labelText: 'Membership Number', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              _saveProfile();
              Navigator.pop(context);
            }, 
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
  
  // C) Payment Methods (Mock)
  void _showPaymentMethodsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Payment Methods', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
             const SizedBox(height: 20),
             ListTile(
               leading: const Icon(Icons.credit_card, size: 30, color: Color(0xFF0B1E3B)),
               title: Text('Visa ending in 4242', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
               subtitle: const Text('Expires 12/25'),
               trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}),
             ),
             const SizedBox(height: 20),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: () => Navigator.pop(context),
                 icon: const Icon(Icons.add),
                 label: const Text('ADD NEW CARD'),
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B1E3B)),
               ),
             ),
          ],
        ),
      ),
    );
  }

  // G) Logout
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out? All your local data will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              // Navigate to Flight Search (Home)
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const FlightSearchScreen()), 
                (route) => false
              );
            }, 
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Help Screen Placeholder
  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help & Support', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  ExpansionTile(title: Text('How do I book a flight?'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Navigate to Search, select your dates and destination, and follow the steps.'))]),
                  ExpansionTile(title: Text('Can I cancel my booking?'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Yes, go to My Bookings and select the booking you wish to cancel.'))]),
                  ExpansionTile(title: Text('Baggage Allowance'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Economy: 23kg, Business: 32kg + 2 Cabin bags.'))]),
                  ExpansionTile(title: Text('Contact Us'), children: [Padding(padding: EdgeInsets.all(16), child: Text('Call us at +1 800-EMIL-AIR or email support@emilairlines.com'))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0B1E3B),
            expandedHeight: 220,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [Color(0xFF0B1E3B), Color(0xFF1E293B)],
                   ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC59D5F), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF1F5F9),
                            child: Text(
                              _profile['name'] != null && _profile['name'].isNotEmpty 
                                ? _profile['name'][0].toUpperCase() 
                                : 'U',
                              style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF0B1E3B)),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC59D5F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile['name'] ?? 'John Doe',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _profile['status'] ?? 'Classic Member',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFFC59D5F),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildMilesCard(),
                  const SizedBox(height: 20),
                  Text(
                    'Account Settings',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0B1E3B)),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    subtitle: 'Update your details',
                    onTap: _showEditProfileDialog,
                  ),
                  _buildSettingTile(
                    icon: Icons.credit_card_rounded,
                    title: 'Payment Methods',
                    subtitle: 'Manage saved cards',
                    onTap: _showPaymentMethodsDialog,
                  ),
                  _buildSettingTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Frequent Flyer',
                    subtitle: _profile['frequentFlyer'] ?? 'Add Number',
                    onTap: _showFrequentFlyerDialog,
                  ),
                   const SizedBox(height: 24),
                   
                  Text(
                    'Preferences',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0B1E3B)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SwitchListTile(
                      value: _notifications,
                      activeColor: const Color(0xFFC59D5F),
                      onChanged: (val) {
                         setState(() => _notifications = val);
                         _saveProfile(showSnack: false);
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Notifications ${val ? 'Enabled' : 'Disabled'}'),
                             duration: const Duration(seconds: 1),
                           )
                         );
                      },
                      title: Text('Notifications', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('Receive flight updates', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.notifications_outlined, color: Color(0xFF0B1E3B), size: 20),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.language, color: Color(0xFF0B1E3B), size: 20),
                      ),
                      title: Text('Language', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _language,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Language Settings',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language,
                                  size: 48,
                                  color: Color(0xFFC59D5F),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Multi-language support is coming soon!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Currently available: English (US)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'OK',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF0B1E3B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSettingTile(
                    icon: Icons.help_outline_rounded, 
                    title: 'Help & Support',
                    onTap: _showHelpSupport,
                  ),
                  
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFFBA1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Miles', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(_profile['miles'] ?? '0', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0B1E3B))),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.trending_up, color: Color(0xFF166534)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon, 
    required String title, 
    String? subtitle,
    required VoidCallback onTap
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0B1E3B), size: 20),
        ),
        title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0B1E3B))),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

}
