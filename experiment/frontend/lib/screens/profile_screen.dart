import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'package:dio/dio.dart';
import 'passenger_main_screen.dart';
import 'purchase_history_screen.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(dioProvider));
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passportController;
  late TextEditingController _nationalityController;
  late TextEditingController _dobController;
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final profile = user?.profile;
    
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _passportController = TextEditingController(text: profile?.passportNumber ?? '');
    _nationalityController = TextEditingController(text: profile?.nationality ?? '');
    
    // birthDate in profile is likely String 'YYYY-MM-DD' from backend
    _dobController = TextEditingController(text: profile?.birthDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _nationalityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final authState = ref.read(authProvider);

      await userService.updateProfile(
        token: authState.token!,
        phoneNumber: _phoneController.text,
        passportNumber: _passportController.text,
        nationality: _nationalityController.text,
        birthDate: _dobController.text.isNotEmpty ? _dobController.text : null,
      );

      // Refresh user data manually or rely on endpoint response if it returns User
      await ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = now;
    
    DateTime initialDate = DateTime(2000, 1, 1); // Safe default
    
    if (_dobController.text.isNotEmpty) {
      try {
        DateTime parsed = DateTime.parse(_dobController.text);
        if (parsed.isAfter(firstDate) && parsed.isBefore(lastDate)) {
             initialDate = parsed;
        }
      } catch (e) {
        // invalid date format, keep default
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Center(child: CircularProgressIndicator());
    
    // We update controllers when not editing to reflect external changes (e.g. refresh)
    if (!_isEditing) {
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.profile?.phoneNumber ?? '';
      _passportController.text = user.profile?.passportNumber ?? '';
      _nationalityController.text = user.profile?.nationality ?? '';
      _dobController.text = user.profile?.birthDate ?? '';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,


        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white),
            onPressed: () {
               ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? LucideIcons.check : LucideIcons.edit2, 
              color: _isEditing ? AppTheme.primaryColor : Colors.white
            ),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Avatar + Name
            Center(
              child: Column(
                children: [
                   Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: AppTheme.primaryColor,
                       boxShadow: [
                         BoxShadow(
                           color: AppTheme.primaryColor.withOpacity(0.3),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         ),
                       ],
                     ),
                     child: const Center(
                       child: Icon(LucideIcons.user, size: 50, color: Colors.white),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     user.fullName ?? 'User',
                     style: const TextStyle(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     user.email,
                     style: const TextStyle(
                       fontSize: 16,
                       color: AppTheme.textSecondary,
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Personal Information Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: LucideIcons.user,
                            enabled: _isEditing,
                          ),
                          const Divider(color: Color(0xFF334155)),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: LucideIcons.phone,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const Divider(color: Color(0xFF334155)),
                          _buildTextField(
                            controller: _dobController,
                            label: 'Date of Birth',
                            icon: LucideIcons.calendar,
                            enabled: _isEditing, // Enable only when editing
                            onTap: _isEditing ? _selectDate : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Travel Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _passportController,
                            label: 'Passport Number',
                            icon: LucideIcons.creditCard, // closest to passport
                            enabled: _isEditing,
                          ),
                          const Divider(color: Color(0xFF334155)),
                          _buildTextField(
                            controller: _nationalityController,
                            label: 'Nationality',
                            icon: LucideIcons.flag,
                            enabled: _isEditing,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Settings / Logout
            Card(
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.history, color: Colors.white),
                    title: const Text('Purchase History', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF334155), height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.logOut, color: AppTheme.errorColor),
                    title: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    final hasTapHandler = onTap != null;
    return GestureDetector(
      onTap: hasTapHandler ? onTap : null,
      child: AbsorbPointer(
        absorbing: hasTapHandler, // If onTap is provided, absorb pointer for text field to prevent focus
        child: TextFormField(
          controller: controller,
          enabled: enabled && !hasTapHandler, // Disable if handled by tap
          keyboardType: keyboardType,
          readOnly: hasTapHandler, // Make read-only if handled by tap
          style: TextStyle(
            color: enabled || hasTapHandler ? Colors.white : AppTheme.textSecondary
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            suffixIcon: hasTapHandler && enabled
                ? const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 20)
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
