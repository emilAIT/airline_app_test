import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'CARD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              initialValue: method,
              items: const [
                DropdownMenuItem(value: 'CARD', child: Text('Card')),
                DropdownMenuItem(value: 'APPLE_PAY', child: Text('Apple Pay')),
                DropdownMenuItem(value: 'GOOGLE_PAY', child: Text('Google Pay')),
              ],
              onChanged: (v) => setState(() => method = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // TODO: вызвать payments API
                Navigator.pop(context, true);
              },
              child: const Text('Pay'),
            )
          ],
        ),
      ),
    );
  }
}