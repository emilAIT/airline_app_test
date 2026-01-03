import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> flightData;
  final Map<String, dynamic> passengerData;
  
  const SeatSelectionScreen({
    Key? key,
    required this.flightData,
    required this.passengerData,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? selectedSeat;
  
  // Mock occupied seats
  final Set<String> occupiedSeats = {
    '1A', '1B', '2C', '3D', '5A', '5F', 
    '7B', '8C', '10A', '12D', '15F', '18A'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(
          'Select Seat',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0B1E3B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
            color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Flight info header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.flightData['from'] ?? 'IST'} → ${widget.flightData['to'] ?? 'JFK'}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.flightData['flightNumber'] ?? 'TK 0001',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Legend
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegend('Available', Colors.white),
                  _buildLegend('Selected', const Color(0xFFC59D5F)),
                  _buildLegend('Occupied', Colors.grey.shade300),
                ],
              ),
            ),
            
            // Seat map
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Economy Class Label
                    Text(
                      'Economy Class',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Seat Grid (30 rows x 6 columns)
                    ...List.generate(30, (rowIndex) {
                      int rowNumber = rowIndex + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left column (A, B, C)
                            _buildSeat(rowNumber, 'A'),
                            _buildSeat(rowNumber, 'B'),
                            _buildSeat(rowNumber, 'C'),
                            
                            // Aisle
                            const SizedBox(width: 40),
                            
                            // Right column (D, E, F)
                            _buildSeat(rowNumber, 'D'),
                            _buildSeat(rowNumber, 'E'),
                            _buildSeat(rowNumber, 'F'),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Confirm button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (selectedSeat != null)
                    Text(
                      'Selected Seat: $selectedSeat',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B1E3B),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedSeat != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    flightData: widget.flightData,
                                    passengerData: widget.passengerData,
                                    seatData: {
                                      'seatNumber': selectedSeat,
                                      'seatPrice': 20.0,
                                    },
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSeat != null
                            ? const Color(0xFF0B1E3B)
                            : Colors.grey,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'CONTINUE TO PAYMENT',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeat(int row, String column) {
    String seatNumber = '$row$column';
    bool isOccupied = occupiedSeats.contains(seatNumber);
    bool isSelected = selectedSeat == seatNumber;
    
    return GestureDetector(
      onTap: isOccupied ? null : () {
        setState(() {
          selectedSeat = seatNumber;
        });
      },
      child: Container(
        width: 45,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isOccupied
              ? Colors.grey.shade300
              : isSelected
                  ? const Color(0xFFC59D5F)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC59D5F)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            seatNumber,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOccupied
                  ? Colors.grey.shade600
                  : isSelected
                      ? Colors.white
                      : const Color(0xFF0B1E3B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
