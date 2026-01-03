import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../create_user/create_user_view.dart';
import '../update_user/update_user_view.dart';

class AdminUsersViewModel extends BaseViewModel {
  final UserService _userService = UserService();
  final NavigationService _navigationService = locator<NavigationService>();

  List<UserPublic> _users = [];
  List<UserPublic> get users => _users;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadUsers() async {
    setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.getUsers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void navigateToCreateUser() {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateUserView(),
        ),
      ).then((_) => loadUsers());
    }
  }

  void navigateToUpdateUser(UserPublic user) {
    final context = _navigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateUserView(
            args: UpdateUserViewArguments(user: user),
          ),
        ),
      ).then((_) => loadUsers());
    }
  }

  void showDeleteDialog(BuildContext context, UserPublic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user ${user.email}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteUser(String userId) async {
    setBusy(true);
    try {
      await _userService.deleteUser(userId);
      await loadUsers();
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      final context = _navigationService.navigatorKey?.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setBusy(false);
    }
  }
}

