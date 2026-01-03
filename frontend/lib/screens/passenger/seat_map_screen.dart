// import 'package:flutter/material.dart';

// class SeatMapScreen extends StatelessWidget {
//   final List<String> occupiedSeats;

//   const SeatMapScreen({super.key, required this.occupiedSeats});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select Seat')),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 4,
//           childAspectRatio: 1,
//         ),
//         itemCount: 40,
//         itemBuilder: (_, i) {
//           final seat = 'A${i + 1}';
//           final occupied = occupiedSeats.contains(seat);

//           return GestureDetector(
//             onTap: occupied ? null : () {},
//             child: Container(
//               margin: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: occupied ? Colors.red : Colors.green,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Center(child: Text(seat)),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }