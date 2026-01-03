import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(
        'Мои бронирования',
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
