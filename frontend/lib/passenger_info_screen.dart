import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'booking_summary_screen.dart';
import 'services/storage_service.dart';
import 'seat_selection_screen.dart';

class PassengerInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedFlight;

  const PassengerInfoScreen({super.key, this.selectedFlight});

  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _gender = 'Male';
  String _countryCode = '+90'; // Default Country Code
  bool _milesMember = false;
  
  // Country Codes List
  final List<String> _countryCodes = ['+1', '+44', '+90', '+49', '+33', '+971', '+91', '+86'];
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _ffProgramController = TextEditingController();
  final TextEditingController _ffNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // Attempt to pre-fill from saved profile
    // Note: In a real app we might check if the user is booking for themselves
    // For now, we assume the primary passenger is the user.
    final profile = StorageService().getProfile();
    if (profile != null) {
      if (profile['name'] != null) {
        final nameParts = (profile['name'] as String).split(' ');
        if (nameParts.isNotEmpty) {
           _firstNameController.text = nameParts[0];
           if (nameParts.length > 1) {
             _lastNameController.text = nameParts.sublist(1).join(' ');
           }
        }
      }
      if (profile['email'] != null) _emailController.text = profile['email'];
      if (profile['phone'] != null) _phoneController.text = profile['phone'];
      if (profile['frequentFlyer'] != null) {
        _milesMember = true;
        _ffNumberController.text = profile['frequentFlyer'];
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _ffProgramController.dispose();
    _ffNumberController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Collect Passenger Data
      final passengerData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'gender': _gender,
        'dob': _dobController.text,
        'email': _emailController.text,
        'phone': '$_countryCode ${_phoneController.text}',
        'passport': _passportController.text,
        'frequentFlyer': _milesMember ? {
          'program': _ffProgramController.text,
          'number': _ffNumberController.text,
        } : null,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SeatSelectionScreen(
              flightData: widget.selectedFlight ?? {},
              passengerData: passengerData,
            )),
      );
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix the errors in the form',
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Passenger Details',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC59D5F)),
            minHeight: 4,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0B1E3B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flight Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                     Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flight_takeoff_rounded, size: 20, color: Color(0xFF0B1E3B)),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             widget.selectedFlight != null 
                              ? '${widget.selectedFlight!['flightNumber']} (${widget.selectedFlight!['from'] ?? 'IST'}-${widget.selectedFlight!['to'] ?? 'JFK'})' 
                              : 'Flight Selection',
                             style: GoogleFonts.manrope(
                               fontWeight: FontWeight.w700,
                               fontSize: 14,
                               color: const Color(0xFF0B1E3B),
                             ),
                           ),
                           Text(
                                                           widget.selectedFlight?['date'] != null 
                                ? (widget.selectedFlight!['date'] is DateTime 
                                    ? '${DateFormat('d MMM, EEE').format(widget.selectedFlight!['date'] as DateTime)} • 1 Passenger'
                                    : '${widget.selectedFlight!['date']} • 1 Passenger')
                                : '12 Oct, Thu • 1 Passenger',
                             style: GoogleFonts.manrope(
                               fontSize: 12,
                               color: const Color(0xFF64748B),
                             ),
                           ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
    
              // Scan Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1E3B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.document_scanner_rounded, color: Color(0xFFC59D5F), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Passport',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Fill details automatically',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 24),
    
              // Form Title
              Text(
                'Adult 1',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              const SizedBox(height: 16),
    
              // Gender Selection
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption('Male'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderOption('Female'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
    
              // Name Fields
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
    
              // Date of Birth
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY) *',
                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  // Simple regex for DD/MM/YYYY
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                    return 'Invalid format (DD/MM/YYYY)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Passport
               TextFormField(
                controller: _passportController,
                decoration: const InputDecoration(labelText: 'Passport Number *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 6) return 'Invalid passport number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
    
              // Contact Info
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  helperText: 'E-ticket will be sent to this email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@') || !value.contains('.')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top because of Helper text on email
                children: [
                  Container(
                    width: 100, // Slightly wider for dropdown
                    margin: const EdgeInsets.only(bottom: 24),
                    child: DropdownButtonFormField<String>(
                      value: _countryCode,
                      decoration: const InputDecoration(
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.all(Radius.circular(12)),
                         ),
                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: _countryCodes.map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(
                          code, 
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF0B1E3B))
                        ),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _countryCode = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 10) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Frequent Flyer Switch
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Frequent Flyer Program',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0B1E3B),
                          ),
                        ),
                        Switch(
                          value: _milesMember,
                          activeColor: const Color(0xFFC59D5F),
                          onChanged: (val) {
                            setState(() {
                              _milesMember = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_milesMember) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ffProgramController,
                        decoration: const InputDecoration(
                          labelText: 'Program',
                          hintText: 'Miles&Smiles',
                        ),
                      ),
                      const SizedBox(height: 12),
                       TextFormField(
                        controller: _ffNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Membership Number',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    
              const SizedBox(height: 32),
    
              // Continue Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('CONTINUE TO SEATS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = label;
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B1E3B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B1E3B) : const Color(0xFFE2E8F0),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
