import 'package:equatable/equatable.dart';

class SeatMap extends Equatable {
  final List<Map<String, dynamic>> seats;

  const SeatMap({required this.seats});

  @override
  List<Object?> get props => [seats];
}
