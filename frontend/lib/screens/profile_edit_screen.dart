// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/zaku_colors.dart';
import 'auth_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _passportNumber = TextEditingController();
  final _nationality = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _passportNumber.dispose();
    _nationality.dispose();
    _dateOfBirth.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _ensureLoggedIn() async {
    if (AuthService.isAuthenticated) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    if (result != true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _load() async {
    await _ensureLoggedIn();
    if (!mounted) return;

    final profile = await ApiService.getMyProfile();

    if (mounted) {
      setState(() {
        _loading = false;
        if (profile != null) {
          _firstName.text = profile['first_name'] ?? '';
          _lastName.text = profile['last_name'] ?? '';
          _passportNumber.text = profile['passport_number'] ?? '';
          _nationality.text = profile['nationality'] ?? '';
          _dateOfBirth.text = profile['date_of_birth'] ?? '';
          _phone.text = profile['phone'] ?? '';
        }
      });
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Обязательно';
    return null;
  }

  DateTime? _safeDateYmd(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final dt = DateTime.utc(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  DateTime? _parseDobFlexible(String input) {
    final v = input.trim();
    if (v.isEmpty) return null;

    // YYYY-MM-DD (preferred) OR YYYY-DD-MM (common mistake)
    final isoLike = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final m1 = isoLike.firstMatch(v);
    if (m1 != null) {
      final year = int.tryParse(m1.group(1)!);
      final a = int.tryParse(m1.group(2)!);
      final b = int.tryParse(m1.group(3)!);
      if (year == null || a == null || b == null) return null;

      final asYmd = _safeDateYmd(year, a, b);
      if (asYmd != null) return asYmd;

      final swapped = _safeDateYmd(year, b, a);
      if (swapped != null) return swapped;
      return null;
    }

    // DD.MM.YYYY or DD-MM-YYYY
    final dmy = RegExp(r'^(\d{2})[.\-](\d{2})[.\-](\d{4})$');
    final m2 = dmy.firstMatch(v);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      final year = int.tryParse(m2.group(3)!);
      if (year == null || month == null || day == null) return null;
      return _safeDateYmd(year, month, day);
    }

    return null;
  }

  String _toIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _dateValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Обязательно';
    final parsed = _parseDobFlexible(v);
    if (parsed == null) return 'Некорректная дата (пример: 2007-02-24)';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedDob = _parseDobFlexible(_dateOfBirth.text);
    if (parsedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Некорректная дата рождения. Используйте YYYY-MM-DD'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dobIso = _toIsoDate(parsedDob);
    _dateOfBirth.text = dobIso;

    setState(() => _saving = true);

    Map<String, dynamic>? saved;
    String? errorMessage;
    try {
      saved = await ApiService.upsertMyProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        passportNumber: _passportNumber.text.trim(),
        nationality: _nationality.text.trim(),
        dateOfBirth: dobIso,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    if (!mounted) return;

    setState(() => _saving = false);

    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Не удалось сохранить профиль'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Настройки профиля',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Заполните данные пассажира',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ZaKuColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'Имя'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Фамилия'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passportNumber,
                    decoration: const InputDecoration(labelText: 'Номер паспорта'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationality,
                    decoration: const InputDecoration(labelText: 'Гражданство'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateOfBirth,
                    decoration: const InputDecoration(
                      labelText: 'Дата рождения',
                      hintText: 'YYYY-MM-DD',
                    ),
                    validator: _dateValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Телефон (необязательно)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZaKuColors.gold,
                        foregroundColor: ZaKuColors.burgundy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: ZaKuColors.burgundy)
                          : Text(
                              'Сохранить',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
