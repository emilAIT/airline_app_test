import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'app_drawer.dart';

class ScaffoldWithDrawer extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool automaticallyImplyLeading;

  const ScaffoldWithDrawer({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();
    
    return FutureBuilder(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: AppTheme.dark900,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            automaticallyImplyLeading: automaticallyImplyLeading,
            actions: actions,
            leading: automaticallyImplyLeading
                ? Builder(
                    builder: (context) => IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.dark700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          size: 24,
                        ),
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
          ),
          drawer: AppDrawer(
            currentUser: snapshot.data,
            onLogout: () async {
              final authService = locator<AuthService>();
              await authService.logout();
              final navigationService = locator<NavigationService>();
              navigationService.replaceWith(Routes.loginView);
            },
          ),
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
      },
    );
  }
}
