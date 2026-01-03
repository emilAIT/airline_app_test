import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<dynamic> _allUsers = [];
  List<dynamic> _staff = [];
  List<dynamic> _passengers = [];
  List<dynamic> _airplanes = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0 = Staff, 1 = All Users

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final allUsersResponse = await apiService.getStaffUsers(); // Get all users
      final staffResponse = await apiService.getStaffUsers(role: 'STAFF', isApproved: true);
      final passengersResponse = await apiService.getStaffUsers(role: 'PASSENGER');
      final airplanesResponse = await apiService.getStaffAirplanes();
      
      if (mounted) {
        setState(() {
          _allUsers = List<dynamic>.from(allUsersResponse.data);
          _staff = List<dynamic>.from(staffResponse.data);
          _passengers = List<dynamic>.from(passengersResponse.data);
          _airplanes = List<dynamic>.from(airplanesResponse.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _promoteToStaff(int userId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.promoteUserToStaff(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User promoted to staff successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to promote user: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteStaff(int userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Are you sure you want to remove $email from staff? This will delete their account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final success = await apiService.deleteStaffUser(userId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Staff member removed successfully')),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to remove staff member')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(int userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete the user account for $email? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final success = await apiService.deleteUser(userId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User deleted successfully')),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete user')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTab == 0
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Staff (${_staff.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedTab == 0
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTab == 1
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'All Users (${_allUsers.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedTab == 1
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildStaffList()
                          : _buildAllUsersList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStaffList() {
    if (_staff.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people,
        title: 'No Staff Members',
        message: 'Promote passengers to staff or create new staff accounts',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final staff = _staff[index];
          final assignedAirplaneId = staff['assigned_airplane_id'];
          final assignedAirplane = _airplanes.firstWhere(
            (a) => a['id'] == assignedAirplaneId,
            orElse: () => null,
          );
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.person, size: 32),
              title: Text(
                staff['email'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Role: ${staff['role'] ?? 'N/A'}'),
                  if (assignedAirplane != null)
                    Text(
                      'Assigned to: ${assignedAirplane['model']} (${assignedAirplane['registration_number']})',
                    ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Remove Staff', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await Future.delayed(Duration.zero);
                      _deleteStaff(staff['id'], staff['email']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllUsersList() {
    if (_allUsers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No Users',
        message: 'No users found in the system',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          final userRole = user['role'] ?? 'N/A';
          final assignedAirplaneId = user['assigned_airplane_id'];
          final assignedAirplane = _airplanes.firstWhere(
            (a) => a['id'] == assignedAirplaneId,
            orElse: () => null,
          );
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                userRole == 'ADMIN'
                    ? Icons.admin_panel_settings
                    : userRole == 'STAFF'
                        ? Icons.person
                        : Icons.person_outline,
                size: 32,
              ),
              title: Text(
                user['email'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Role: $userRole'),
                  if (userRole == 'STAFF')
                    Text(
                      assignedAirplane != null
                          ? 'Assigned to: ${assignedAirplane['model']} (${assignedAirplane['registration_number']})'
                          : 'Not assigned to any airplane',
                    ),
                ],
              ),
              trailing: userRole == 'ADMIN'
                  ? null
                  : PopupMenuButton(
                      itemBuilder: (context) => [
                        if (userRole == 'PASSENGER')
                          PopupMenuItem(
                            child: const Text('Promote to Staff'),
                            onTap: () async {
                              await Future.delayed(Duration.zero);
                              _showPromoteDialog(context, user);
                            },
                          ),
                        PopupMenuItem(
                          child: const Text('Delete User', style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await Future.delayed(Duration.zero);
                            _deleteUser(user['id'], user['email']);
                          },
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }



  void _showPromoteDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Promote ${user['email']} to Staff'),
        content: const Text('Are you sure you want to promote this user to staff?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _promoteToStaff(user['id']);
              Navigator.of(context).pop();
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }
}

