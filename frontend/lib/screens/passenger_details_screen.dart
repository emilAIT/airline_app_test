// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/zaku_colors.dart';
import 'booking_pending_screen.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final dynamic flight;
  final List<String> selectedSeats;

  const PassengerDetailsScreen({
    super.key,
    required this.flight,
    required this.selectedSeats,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<Map<String, TextEditingController>> _controllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _prefillCurrentUser();
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.selectedSeats.length,
      (index) => {
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'passport': TextEditingController(),
        'nationality': TextEditingController(),
        'dob': TextEditingController(),
      },
    );
  }

  Future<void> _prefillCurrentUser() async {
    if (AuthService.isAuthenticated) {
      try {
        final profile = await ApiService.getMyProfile();

        if (profile == null) return;

        final isComplete =
            (profile['first_name'] ?? '').toString().trim().isNotEmpty &&
            (profile['last_name'] ?? '').toString().trim().isNotEmpty &&
            (profile['passport_number'] ?? '').toString().trim().isNotEmpty &&
            (profile['nationality'] ?? '').toString().trim().isNotEmpty &&
            (profile['date_of_birth'] ?? '').toString().trim().isNotEmpty;

        // Do not block booking if profile is incomplete.
        // Passenger details are captured in this screen for each ticket.
        if (!isComplete) return;

        if (mounted) {
          setState(() {
            _controllers[0]['firstName']?.text = profile['first_name'] ?? '';
            _controllers[0]['lastName']?.text = profile['last_name'] ?? '';
            _controllers[0]['passport']?.text =
                profile['passport_number'] ?? '';
            _controllers[0]['nationality']?.text = profile['nationality'] ?? '';
            _controllers[0]['dob']?.text = profile['date_of_birth'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error prefilling profile: $e');
      }
    }
  }

  @override
  void dispose() {
    for (final map in _controllers) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final passengers = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.selectedSeats.length; i++) {
      passengers.add({
        'first_name': _controllers[i]['firstName']!.text,
        'last_name': _controllers[i]['lastName']!.text,
        'seat_number': widget.selectedSeats[i],
        'passport_number': _controllers[i]['passport']!.text,
        'nationality': _controllers[i]['nationality']!.text,
        'date_of_birth': _controllers[i]['dob']!.text,
      });
    }

    Map<String, dynamic>? result;
    String? errorMessage;
    try {
      result = await ApiService.createBooking(
        widget.flight['id'],
        widget.selectedSeats,
        passengerDetails: passengers,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование успешно создано!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => BookingPendingScreen(booking: result!),
          ),
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage ?? 'Ошибка создания бронирования. Проверьте данные.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Данные пассажиров',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ZaKuColors.burgundy,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.selectedSeats.length,
                separatorBuilder: (c, i) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _buildPassengerForm(index);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZaKuColors.gold,
                      foregroundColor: ZaKuColors.burgundy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: ZaKuColors.burgundy,
                          )
                        : Text(
                            'Подтвердить бронирование (${widget.selectedSeats.length} чел.)',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildPassengerForm(int index) {
    final ctrls = _controllers[index];
    final seat = widget.selectedSeats[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Пассажир ${index + 1}',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ZaKuColors.burgundy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ZaKuColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Место $seat',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: ZaKuColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(ctrls['firstName']!, 'Имя', 'Ivan'),
          const SizedBox(height: 12),
          _buildTextField(ctrls['lastName']!, 'Фамилия', 'Ivanov'),
          const SizedBox(height: 12),
          _buildTextField(ctrls['passport']!, 'Номер паспорта', 'AC1234567'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  ctrls['nationality']!,
                  'Гражданство',
                  'Kyrgyzstan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  ctrls['dob']!,
                  'Дата рождения (YYYY-MM-DD)',
                  '2000-01-01',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        fillColor: Colors.grey[50],
        filled: true,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Обязательно' : null,
    );
  }
}
