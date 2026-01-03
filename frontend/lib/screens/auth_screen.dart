import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/zaku_colors.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  final bool popOnSuccess;
  final VoidCallback? onAuthenticated;
  const AuthScreen({
    super.key,
    this.isLogin = true,
    this.popOnSuccess = true,
    this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLogin;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    isLogin = widget.isLogin;
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Заполните поля')));
      return;
    }
    setState(() => _isLoading = true);

    String? error;
    if (isLogin) {
      error = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      error = await AuthService.register(
          _emailController.text, _passwordController.text);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        if (widget.popOnSuccess) {
          Navigator.pop(context, true);
        } else {
          widget.onAuthenticated?.call();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ZaKuColors.burgundy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isLogin ? 'Вход' : 'Регистрация',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ZaKuColors.burgundy,
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                helperText: isLogin ? null : 'Минимум 8 символов',
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZaKuColors.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Нет аккаунта? Регистрация' : 'Есть аккаунт? Вход'),
            ),
            if (isLogin) ...[
              const SizedBox(height: 24),
              const SelectableText(
                'Staff: staff@zaku.kz / staff123',
                style: TextStyle(color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
