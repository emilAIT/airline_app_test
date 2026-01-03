import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'main_navigation_screen.dart';
import '../widgets/glow_button.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      if (_isLogin) {
        success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authProvider.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else if (mounted) {
        _showErrorSnack(_isLogin ? 'Invalid credentials' : 'Registration failed');
      }
    } catch (e) {
      if (mounted) _showErrorSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EldiyarTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ResizeToAvoidBottomInset: false means the background and main layout 
      // won't smoosh when keyboard opens. 
      // However, for strict "no scroll" assurance, we might want to let it resize 
      // but ensure our content fits. 
      // Given the prompt "Eliminate vertical scrolling entirely", we'll try `false`
      // but that might hide inputs. 
      // Setting it to `true` (default) is safer for function, 
      // but we will design the UI to fit perfectly in the available space.
      resizeToAvoidBottomInset: true, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Deep Navy / Slate 900
              Color(0xFF1E293B), // Slate 800
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER SECTION (Approx 30%) ---
                  const Spacer(flex: 3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff, color: EldiyarTheme.primaryBlue, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'ELDIK AirLines',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Premium Travel Experience' : 'Join the Elite',
                        style: TextStyle(
                          color: EldiyarTheme.textSecondary.withOpacity(0.8),
                          letterSpacing: 1,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),

                  // --- MAIN CARD SECTION ---
                  // We use a clean glass/dark card for inputs
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) ...[
                            _buildInput(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              isLast: false,
                            ),
                            const SizedBox(height: 20),
                          ],
                          _buildInput(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            isLast: false,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildInput(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isLast: true,
                            isPassword: true,
                          ),
                          
                          if (_isLogin) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: EldiyarTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          
                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            child: GlowButton(
                              label: _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                              icon: Icons.arrow_forward,
                              onPressed: _isLoading ? null : _handleSubmit,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // --- FOOTER SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "New to Eldiyar?" : "Already a member?",
                        style: TextStyle(color: EldiyarTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                           // Clear errors or fields if desired
                           setState(() => _isLogin = !_isLogin);
                        },
                        child: Text(
                          _isLogin ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isLast = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isLast ? (_) => _handleSubmit() : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: EldiyarTheme.textSecondary),
        prefixIcon: Icon(icon, color: EldiyarTheme.primaryBlue.withOpacity(0.8), size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EldiyarTheme.primaryBlue, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (!isPassword && label.contains('Email') && !value.contains('@')) {
          return 'Invalid Email';
        }
        if (isPassword && value.length < 6) return 'Min 6 chars';
        return null;
      },
    );
  }
}

