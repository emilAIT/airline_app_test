import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'update_user_viewmodel.dart';
import '../../../models/user_model.dart';

class UpdateUserViewArguments {
  final UserPublic user;
  UpdateUserViewArguments({required this.user});
}

class UpdateUserView extends StackedView<UpdateUserViewModel> {
  final UpdateUserViewArguments args;

  const UpdateUserView({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, UpdateUserViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update User ${args.user.email}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewModel.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: viewModel.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (leave empty to keep current)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: viewModel.fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: viewModel.isActive,
                decoration: const InputDecoration(
                  labelText: 'Is Active',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: (value) {
                  viewModel.isActive = value ?? true;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: viewModel.role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: UserRole.passenger, child: Text('Passenger')),
                  DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
                ],
                onChanged: (value) {
                  viewModel.role = value ?? UserRole.passenger;
                },
              ),
              const SizedBox(height: 24),
              if (viewModel.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: viewModel.isBusy ? null : viewModel.updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: viewModel.isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update User',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  UpdateUserViewModel viewModelBuilder(BuildContext context) =>
      UpdateUserViewModel(user: args.user);
}

