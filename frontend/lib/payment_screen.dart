import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'boarding_pass_screen.dart';
import 'payment_success_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> flightData;
  final Map<String, dynamic> passengerData;
  final Map<String, dynamic> seatData;

  const PaymentScreen({
    super.key, 
    required this.flightData, 
    required this.passengerData,
    required this.seatData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  
  final _cardNumController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedPaymentMethod = 'card'; // Default to card
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Visa, Mastercard, Amex',
    },
    {
      'id': 'paypal',
      'name': 'PayPal',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay with your PayPal account',
    },
    {
      'id': 'apple_pay',
      'name': 'Apple Pay',
      'icon': Icons.apple,
      'description': 'Quick checkout with Apple Pay',
    },
    {
      'id': 'google_pay',
      'name': 'Google Pay',
      'icon': Icons.account_balance,
      'description': 'Pay with Google Pay',
    },
    {
      'id': 'miles',
      'name': 'Miles & Points',
      'icon': Icons.card_giftcard,
      'description': 'Redeem your miles',
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Direct bank payment',
    },
  ];

  double get _totalPrice {
    final flightPrice = (widget.flightData['price'] is double) 
        ? widget.flightData['price'] 
        : double.tryParse(widget.flightData['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        
    final seatPrice = (widget.seatData['seatPrice'] is double) 
        ? widget.seatData['seatPrice'] 
        : double.tryParse(widget.seatData['seatPrice'].toString()) ?? 0.0;
        
    return flightPrice + seatPrice;
  }

  Future<void> _processPayment() async {
    // Validate based on payment method
    if (_selectedPaymentMethod == 'card' && !_validateCardForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all card details',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing (2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Generate booking reference
      final bookingRef = 'PNR${Random().nextInt(90000) + 10000}';

      // Create booking data (flat structure as requested)
      final bookingData = {
        'bookingId': bookingRef,
        'pnr': bookingRef,
        'status': 'CONFIRMED',
        'from': widget.flightData['from'] ?? 'IST',
        'fromCity': widget.flightData['fromCity'] ?? 'Istanbul',
        'to': widget.flightData['to'] ?? 'JFK',
        'toCity': widget.flightData['toCity'] ?? 'New York',
        'flightNumber': widget.flightData['flightNumber'] ?? 'TK 0001',
        'date': widget.flightData['date'] is DateTime 
            ? (widget.flightData['date'] as DateTime).toIso8601String()
            : widget.flightData['date']?.toString() ?? DateTime.now().toIso8601String(),
        'departureTime': widget.flightData['departureTime'] ?? '13:05',
        'arrivalTime': widget.flightData['arrivalTime'] ?? '17:35',
        'passengerName': '${widget.passengerData['firstName']} ${widget.passengerData['lastName']}',
        'firstName': widget.passengerData['firstName'],
        'lastName': widget.passengerData['lastName'],
        'passengerEmail': widget.passengerData['email'],
        'passengerPhone': widget.passengerData['phone'],
        'seat': widget.seatData['seatNumber'] ?? '14A',
        'seatNumber': widget.seatData['seatNumber'] ?? '14A',
        'gate': 'A${Random().nextInt(20) + 1}',
        'price': _totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        'bookingDate': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save to SharedPreferences using user's requested format
      final prefs = await SharedPreferences.getInstance();
      List<String> bookings = prefs.getStringList('bookings') ?? [];
      bookings.add(jsonEncode(bookingData));
      await prefs.setStringList('bookings', bookings);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Navigate to success screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            bookingData: bookingData,
          ),
        ),
        (route) => route.isFirst, // Keep only the home screen in stack
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking confirmed! Reference: $bookingRef',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF166534),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  bool _validateCardForm() {
    return _cardNumController.text.length >= 16 &&
           _expiryController.text.isNotEmpty &&
           _cvvController.text.length >= 3 &&
           _nameController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final String flightNum = widget.flightData['flightNumber'] ?? 'N/A';
    final String route = '${widget.flightData['from'] ?? 'IST'} → ${widget.flightData['to'] ?? 'JFK'}';
    final String date = widget.flightData['date'] is DateTime 
        ? DateFormat('d MMM yyyy').format(widget.flightData['date'] as DateTime) 
        : widget.flightData['date']?.toString() ?? 'N/A';
        
    final String passengerName = '${widget.passengerData['firstName']} ${widget.passengerData['lastName']}';
    final String seat = widget.seatData['seatNumber'] ?? 'N/A';

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showCancelDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Payment', 
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)
          ),
          backgroundColor: const Color(0xFF0B1E3B),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              final shouldPop = await _showCancelDialog();
              if (shouldPop == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isProcessing 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Processing Secure Payment...', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Booking Summary
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Summary',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Flight', flightNum),
                            _buildSummaryRow('Route', route),
                            _buildSummaryRow('Date', date),
                            _buildSummaryRow('Passenger', passengerName),
                            _buildSummaryRow('Seat', seat),
                          ],
                        ),
                      ),
                    ),

                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text('Total Amount', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF0B1E3B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Payment Methods Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Payment Method',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B1E3B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Payment method grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _paymentMethods.length,
                            itemBuilder: (context, index) {
                              final method = _paymentMethods[index];
                              final isSelected = _selectedPaymentMethod == method['id'];
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = method['id'];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                        ? const Color(0xFFC59D5F) 
                                        : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: const Color(0xFFC59D5F).withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        method['icon'],
                                        color: isSelected 
                                          ? const Color(0xFFC59D5F) 
                                          : const Color(0xFF64748B),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          method['name'],
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: isSelected 
                                              ? FontWeight.w700 
                                              : FontWeight.w600,
                                            color: isSelected 
                                              ? const Color(0xFF0B1E3B) 
                                              : const Color(0xFF64748B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFC59D5F),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Form(
                      key: _formKey,
                      child: _buildPaymentForm(),
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534), // Green for pay
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 16),
                          const SizedBox(width: 8),
                          Text(_getPayButtonText()),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                         final shouldPop = await _showCancelDialog();
                         if (shouldPop == true && mounted) Navigator.pop(context);
                      },
                      child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Payment?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to go back? Your payment information will not be saved.',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
              style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Go Back',
              style: GoogleFonts.manrope(
                color: const Color(0xFFBA1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedPaymentMethod) {
      case 'card':
        return _buildCardForm();
      case 'paypal':
        return _buildPayPalForm();
      case 'apple_pay':
        return _buildApplePayForm();
      case 'google_pay':
        return _buildGooglePayForm();
      case 'miles':
        return _buildMilesForm();
      case 'bank_transfer':
        return _buildBankTransferForm();
      default:
        return _buildCardForm();
    }
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B1E3B),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardNumController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
          validator: (val) => (val?.length ?? 0) < 16 ? 'Invalid Card' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  hintText: '12/25',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(3)],
                validator: (val) => (val?.length ?? 0) < 3 ? 'Invalid' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildPayPalForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Color(0xFF0070BA), // PayPal blue
              ),
              const SizedBox(height: 16),
              Text(
                'Pay with PayPal',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll be redirected to PayPal to complete your payment securely.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'PayPal Email',
                  hintText: 'your.email@paypal.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplePayForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.apple,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Apple Pay',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Touch ID or Face ID to complete payment',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Text(
                  'Ready to pay',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGooglePayForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              size: 48,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Google Pay',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pay quickly using your Google account',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 32),
                const SizedBox(width: 12),
                Text(
                  'user@gmail.com',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilesForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC59D5F), Color(0xFF8B6F47)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.card_giftcard,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Available Miles',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '45,230 Miles',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Required for this booking: 35,000 miles',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Miles to Redeem',
            hintText: '35000',
            suffixText: 'miles',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBankTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFA726)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFFA726)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your booking will be held for 24 hours pending payment confirmation',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF0B1E3B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bank Account Details',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B1E3B),
          ),
        ),
        const SizedBox(height: 12),
        _buildBankDetail('Bank Name', 'Emirates National Bank'),
        _buildBankDetail('Account Number', '1234567890'),
        _buildBankDetail('SWIFT Code', 'ENBDAEADXXX'),
        _buildBankDetail('Reference', 'TK0001-${DateTime.now().millisecondsSinceEpoch}'),
      ],
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1E3B),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPayButtonText() {
    switch (_selectedPaymentMethod) {
      case 'paypal':
        return 'CONTINUE TO PAYPAL';
      case 'apple_pay':
        return 'PAY WITH APPLE PAY';
      case 'google_pay':
        return 'PAY WITH GOOGLE PAY';
      case 'miles':
        return 'REDEEM MILES';
      case 'bank_transfer':
        return 'CONFIRM BOOKING';
      default:
        return 'PAY \$${_totalPrice.toStringAsFixed(2)}';
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(color: const Color(0xFF64748B))),
          Flexible(
            child: Text(
              value, 
              style: GoogleFonts.manrope(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF0B1E3B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
