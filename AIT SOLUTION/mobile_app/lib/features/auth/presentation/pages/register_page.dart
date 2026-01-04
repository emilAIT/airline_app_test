import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ait_airlines/core/utils/navigation_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  String _selectedRole = 'passenger';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passportNumberController.dispose();
    _nationalityController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep space blue
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.status == 'pending_approval') {
              // If staff registered successfully, they stay on login but see a message
              context.read<AuthBloc>().add(AuthLogoutRequested()); // Clear the "authenticated" state for pending staff
              _showApprovalDialog(context);
            } else {
              navigateToHome(context);
            }
          }
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background Elements (Gradients/Orbs)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE94560).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Join Us',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text(
                          'Create an account to start your journey',
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                        const SizedBox(height: 32),

                        // ROLE SELECTION
                        const Text(
                          'REGISTER AS',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRoleButton('passenger', 'Passenger', Icons.person),
                            const SizedBox(width: 16),
                            _buildRoleButton('staff', 'Staff', Icons.badge),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Form Fields with Glassmorphism
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'John',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Doe',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'example@ait.com',
                          icon: Icons.alternate_email,
                          validator: (v) => v!.contains('@') ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscure: _obscurePassword,
                          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '+77771234567',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passportNumberController,
                          label: 'Passport ID',
                          hint: 'N1234567',
                          icon: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _nationalityController,
                          label: 'Nationality',
                          hint: 'Kazakhstan',
                          icon: Icons.flag_outlined,
                        ),
                        
                        if (_selectedRole == 'staff') ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _staffIdController,
                            label: 'Employee ID',
                            hint: 'EMP-123456',
                            icon: Icons.badge_outlined,
                            validator: (v) => v!.isEmpty ? 'Staff ID is required' : null,
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Terms and Privacy
                        _buildCheckboxRow('I agree to the Terms of Service', (v) {}),
                        const SizedBox(height: 8),
                        _buildCheckboxRow('I consent to the Privacy Policy', (v) {}),
                        
                        const SizedBox(height: 40),
                        
                        // Register Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE94560), Color(0xFFF05D7A)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE94560).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'GET STARTED',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        
                        Center(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Colors.white60),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: Color(0xFFE94560),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE94560) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFE94560) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white54),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Registration Successful', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your Staff account has been created and is now awaiting administrator approval. You will be able to log in once your account is active.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String text, Function(bool?)? onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: true, // For demo, keep it true
            onChanged: onChanged,
            activeColor: const Color(0xFFE94560),
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: Icon(icon, color: Colors.white54, size: 22),
              suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                    onPressed: toggleObscure,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          passportNumber: _passportNumberController.text.isNotEmpty ? _passportNumberController.text : null,
          nationality: _nationalityController.text.isNotEmpty ? _nationalityController.text : null,
          role: _selectedRole,
        ),
      );
    }
  }
}
