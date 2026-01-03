// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/zaku_colors.dart';

class AddAircraftScreen extends StatefulWidget {
  const AddAircraftScreen({super.key});

  @override
  State<AddAircraftScreen> createState() => _AddAircraftScreenState();
}

class _AddAircraftScreenState extends State<AddAircraftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _totalRowsController = TextEditingController(text: '30');
  final _seatsPerRowController = TextEditingController(text: '6');
  final _extraLegroomController = TextEditingController(text: '3');

  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _totalRowsController.dispose();
    _seatsPerRowController.dispose();
    _extraLegroomController.dispose();
    super.dispose();
  }

  int get _totalRows => int.tryParse(_totalRowsController.text) ?? 0;
  int get _seatsPerRow => int.tryParse(_seatsPerRowController.text) ?? 0;
  int get _extraLegroom => int.tryParse(_extraLegroomController.text) ?? 0;

  void _previewMap() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _showPreview = true);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validation
    if (_extraLegroom > _totalRows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Extra legroom rows ($_extraLegroom) cannot exceed total rows ($_totalRows)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.staffCreateAirplaneWithSeats(
        name: _nameController.text.trim(),
        modelType: _modelController.text.trim(),
        totalRows: _totalRows,
        seatsPerRow: _seatsPerRow,
        extraLegroomRowsCount: _extraLegroom,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aircraft created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Aircraft',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Aircraft Name / Registration',
                        hintText: 'e.g., UP-B7701',
                        prefixIcon: const Icon(Icons.airplanemode_active),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'Aircraft Model',
                        hintText: 'e.g., Boeing 737-800',
                        prefixIcon: const Icon(Icons.flight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _totalRowsController,
                      decoration: InputDecoration(
                        labelText: 'Total Rows',
                        prefixIcon: const Icon(Icons.table_rows),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatsPerRowController,
                      decoration: InputDecoration(
                        labelText: 'Seats Per Row',
                        hintText: 'e.g., 6 for A-F',
                        prefixIcon: const Icon(Icons.event_seat),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0 || val > 10) {
                          return 'Must be 1-10';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _extraLegroomController,
                      decoration: InputDecoration(
                        labelText: 'Extra Legroom Rows (from row 1)',
                        prefixIcon: const Icon(Icons.add_circle_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 0) return 'Must be >= 0';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _previewMap,
                      icon: const Icon(Icons.visibility),
                      label: Text(
                        'Preview Seat Map',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: ZaKuColors.burgundy),
                        foregroundColor: ZaKuColors.burgundy,
                      ),
                    ),
                    if (_showPreview) ...[
                      const SizedBox(height: 24),
                      _buildPreview(),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZaKuColors.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Aircraft',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_totalRows <= 0 || _seatsPerRow <= 0) {
      return Text(
        'Invalid configuration',
        style: GoogleFonts.montserrat(color: Colors.red),
      );
    }

    final seatLetters = List.generate(
      _seatsPerRow,
      (i) => String.fromCharCode(65 + i),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ZaKuColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seat Map Preview',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ZaKuColors.burgundy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Extra Legroom',
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text('Standard', style: GoogleFonts.montserrat(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _seatsPerRow,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _totalRows * _seatsPerRow,
              itemBuilder: (context, index) {
                final row = (index ~/ _seatsPerRow) + 1;
                final col = index % _seatsPerRow;
                final seatLetter = seatLetters[col];
                final seatNumber = '$row$seatLetter';

                final isExtraLegroom = row <= _extraLegroom;
                final color = isExtraLegroom
                    ? const Color(0xFFFFD700)
                    : Colors.white;

                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isExtraLegroom
                          ? const Color(0xFFB8860B)
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    seatNumber,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isExtraLegroom ? Colors.black87 : Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
