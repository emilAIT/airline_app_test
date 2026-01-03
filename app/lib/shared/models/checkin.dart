class CheckIn {
  final int id;
  final int ticketId;
  final DateTime checkedInAt;
  final String qrCode;

  CheckIn({
    required this.id,
    required this.ticketId,
    required this.checkedInAt,
    required this.qrCode,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: (json['id'] as num).toInt(),
      ticketId: (json['ticket_id'] as num).toInt(),
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
      qrCode: json['qr_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'checked_in_at': checkedInAt.toIso8601String(),
      'qr_code': qrCode,
    };
  }
}

