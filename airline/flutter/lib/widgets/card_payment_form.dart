// WIDGET: CardPaymentForm
// PURPOSE: Card input form for CARD payment method
// USED BY: PaymentScreen
// NOTE: Data is validated but NOT sent to backend (mock payment)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CardPaymentForm extends StatefulWidget {
  final void Function(bool isValid) onValidationChanged;
  final void Function(Map<String, String> details)? onDetailsChanged;

  const CardPaymentForm({
    super.key, 
    required this.onValidationChanged,
    this.onDetailsChanged,
  });

  @override
  State<CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  void _validate() {
    final valid = _formKey.currentState?.validate() ?? false;
    widget.onValidationChanged(valid);
    
    if (widget.onDetailsChanged != null) {
      widget.onDetailsChanged!({
        'cardNumber': _cardNumber.text,
        'cardHolder': _cardHolder.text,
        'expiry': _expiry.text,
        'cvv': _cvv.text,
      });
    }
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        onChanged: _validate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EldiyarTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Card Number
            TextFormField(
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EldiyarTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: const Icon(Icons.credit_card, color: EldiyarTheme.primaryBlue),
                filled: true,
                fillColor: EldiyarTheme.cardBackground.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EldiyarTheme.primaryBlue, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              validator: (v) =>
                  v == null || v.length < 13 ? 'Invalid card number' : null,
            ),

            const SizedBox(height: 12),

            // Card Holder
            TextFormField(
              controller: _cardHolder,
              style: const TextStyle(color: EldiyarTheme.textPrimary),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'JOHN DOE',
                prefixIcon: const Icon(Icons.person, color: EldiyarTheme.primaryBlue),
                filled: true,
                fillColor: EldiyarTheme.cardBackground.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EldiyarTheme.primaryBlue, width: 2),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Expiry
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: EldiyarTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/27',
                      prefixIcon: const Icon(Icons.calendar_today, color: EldiyarTheme.primaryBlue),
                      filled: true,
                      fillColor: EldiyarTheme.cardBackground.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: EldiyarTheme.primaryBlue, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    validator: (v) => v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v)
                        ? 'Invalid'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // CVV
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(color: EldiyarTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: const Icon(Icons.lock, color: EldiyarTheme.primaryBlue),
                      filled: true,
                      fillColor: EldiyarTheme.cardBackground.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: EldiyarTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: EldiyarTheme.primaryBlue, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) => v == null || v.length < 3 ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for MM/YY formatting
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 2 && !text.contains('/')) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    return newValue;
  }
}
