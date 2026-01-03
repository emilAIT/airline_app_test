import 'enums.dart';

class SeatTemplate {
  final int id;
  final int rowNumber;
  final String seatLabel;
  final SeatCategory category;

  SeatTemplate({
    required this.id,
    required this.rowNumber,
    required this.seatLabel,
    required this.category,
  });

  factory SeatTemplate.fromJson(Map<String, dynamic> json) {
    return SeatTemplate(
      id: (json['id'] as num).toInt(),
      rowNumber: (json['row_number'] as num).toInt(),
      seatLabel: json['seat_label'] as String,
      category: SeatCategory.fromJson(json['category'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row_number': rowNumber,
      'seat_label': seatLabel,
      'category': category.toJson(),
    };
  }
  
  String get seatNumber => '$rowNumber$seatLabel';
}

