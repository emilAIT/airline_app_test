import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

enum PaymentMethod {
  @JsonValue('CARD')
  card,
  @JsonValue('APPLE_PAY')
  applePay,
  @JsonValue('GOOGLE_PAY')
  googlePay,
}

enum PaymentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('PAID')
  paid,
  @JsonValue('FAILED')
  failed,
}

@JsonSerializable()
class PaymentPublic {
  final String id;
  @JsonKey(name: 'booking_id')
  final String bookingId;
  final PaymentMethod method;
  final PaymentStatus status;
  @JsonKey(name: 'idempotency_key')
  final String idempotencyKey;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  PaymentPublic({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
  });

  factory PaymentPublic.fromJson(Map<String, dynamic> json) =>
      _$PaymentPublicFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentPublicToJson(this);
}

@JsonSerializable()
class PaymentsPublic {
  final List<PaymentPublic> data;
  final int count;

  PaymentsPublic({
    required this.data,
    required this.count,
  });

  factory PaymentsPublic.fromJson(Map<String, dynamic> json) =>
      _$PaymentsPublicFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentsPublicToJson(this);
}

@JsonSerializable()
class PaymentCreate {
  @JsonKey(name: 'booking_id')
  final String bookingId;
  final PaymentMethod method;
  @JsonKey(name: 'idempotency_key')
  final String idempotencyKey;

  PaymentCreate({
    required this.bookingId,
    required this.method,
    required this.idempotencyKey,
  });

  factory PaymentCreate.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateToJson(this);
}
