import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'admin_users_viewmodel.dart';
import '../../../models/user_model.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminUsersViewModel>.reactive(
      viewModelBuilder: () => AdminUsersViewModel()..loadUsers(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Users Management'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: viewModel.isBusy
            ? const Center(child: CircularProgressIndicator())
            : viewModel.hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage ?? 'Unknown error',
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: viewModel.loadUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: viewModel.loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.users.length,
                      itemBuilder: (context, index) {
                        final user = viewModel.users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.role == UserRole.staff 
                                  ? Colors.orange.shade100 
                                  : Colors.blue.shade100,
                              child: Icon(
                                user.role == UserRole.staff ? Icons.admin_panel_settings : Icons.person,
                                color: user.role == UserRole.staff 
                                    ? Colors.orange.shade700 
                                    : Colors.blue.shade700,
                              ),
                            ),
                            title: Text(
                              user.fullName ?? user.email,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(user.email),
                                Text(
                                  'Role: ${user.role == UserRole.staff ? "Staff" : "Passenger"}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    viewModel.navigateToUpdateUser(user);
                                    break;
                                  case 'delete':
                                    viewModel.showDeleteDialog(context, user);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: viewModel.navigateToCreateUser,
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

