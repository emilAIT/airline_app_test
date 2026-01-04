import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ait_airlines/features/auth/presentation/bloc/auth_state.dart';
import 'package:ait_airlines/core/network/api_client.dart';
import 'package:ait_airlines/core/di/injection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.dio.get('/users/me/profile');
      if (response.statusCode == 200) {
        setState(() {
          _profileData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/profile/edit');
              _loadProfile(); // Reload after editing
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Please login to view profile'));
          }
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = state.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_profileData?['first_name'] ?? user.firstName ?? 'No first name'),
                  subtitle: const Text('First name'),
                ),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(_profileData?['last_name'] ?? user.lastName ?? 'No last name'),
                  subtitle: const Text('Last name'),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(user.email),
                  subtitle: const Text('Email'),
                ),
                if (_profileData?['phone'] != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(_profileData!['phone']),
                    subtitle: const Text('Phone'),
                  ),
                if (_profileData?['passport_number'] != null)
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: Text(_profileData!['passport_number']),
                    subtitle: const Text('Passport ID'),
                  ),
                if (_profileData?['nationality'] != null)
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text(_profileData!['nationality']),
                    subtitle: const Text('Nationality'),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/profile/edit');
                      _loadProfile();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


