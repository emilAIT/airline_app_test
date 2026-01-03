import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/auth_screen.dart';
import '../screens/main_screen.dart';
import '../screens/staff_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../theme/zaku_colors.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AuthService.init();
    if (!mounted) return;
    setState(() => _isLoaded = true);
  }

  void _update() => setState(() {});

  Widget _home() {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!AuthService.isAuthenticated) {
      return AuthScreen(popOnSuccess: false, onAuthenticated: _update);
    }

    if (AuthService.isStaff) {
      return StaffDashboardScreen(onAuthChanged: _update);
    }

    return MainScreen(onAuthChanged: _update);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZaKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ZaKuColors.burgundy,
          primary: ZaKuColors.burgundy,
          secondary: ZaKuColors.gold,
        ),
        textTheme: GoogleFonts.montserratTextTheme(),
        primaryTextTheme: GoogleFonts.montserratTextTheme(),
        scaffoldBackgroundColor: ZaKuColors.cream,
      ),
      home: _home(),
    );
  }
}
