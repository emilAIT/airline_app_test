import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getProfiles();

      if (mounted) {
        setState(() {
          _profiles = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profiles: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProfile(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteProfile(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile deleted'), backgroundColor: Colors.green),
        );
        _loadProfiles();
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = e.response?.data?['detail'] ?? 'Failed to delete profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.toString()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    Widget content = _isLoading
        ? const LoadingWidget()
        : _profiles.isEmpty
            ? EmptyStateWidget(
                title: 'No Profiles',
                icon: Icons.person_add_outlined,
                message: 'You haven\'t added any profiles yet.',
                onRetry: _loadProfiles,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _profiles.length,
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                profile['full_name'] ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) => EditProfileScreen(profile: profile),
                                            ),
                                          )
                                          .then((_) => _loadProfiles());
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(profile['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow('Passport', profile['passport_number']),
                          _buildInfoRow('Nationality', profile['nationality']),
                          _buildInfoRow(
                            'DOB',
                            profile['date_of_birth'] != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(DateTime.parse(profile['date_of_birth']))
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

    if (!widget.showAppBar) {
      return Scaffold(
        body: content,
        floatingActionButton: _buildFAB(authService),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: _buildFAB(authService),
    );
  }

  Widget? _buildFAB(AuthService authService) {
    if (authService.user?['role'] == 'PASSENGER' || _profiles.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              )
              .then((_) => _loadProfiles());
        },
        label: const Text('Add Profile'),
        icon: const Icon(Icons.person_add),
      );
    }
    return null;
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('Are you sure you want to delete this profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProfile(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }
}
