// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentPublic _$PaymentPublicFromJson(Map<String, dynamic> json) =>
    PaymentPublic(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      idempotencyKey: json['idempotency_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PaymentPublicToJson(PaymentPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking_id': instance.bookingId,
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'idempotency_key': instance.idempotencyKey,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.card: 'CARD',
  PaymentMethod.applePay: 'APPLE_PAY',
  PaymentMethod.googlePay: 'GOOGLE_PAY',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'PENDING',
  PaymentStatus.paid: 'PAID',
  PaymentStatus.failed: 'FAILED',
};

PaymentsPublic _$PaymentsPublicFromJson(Map<String, dynamic> json) =>
    PaymentsPublic(
      data: (json['data'] as List<dynamic>)
          .map((e) => PaymentPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentsPublicToJson(PaymentsPublic instance) =>
    <String, dynamic>{
      'data': instance.data,
      'count': instance.count,
    };

PaymentCreate _$PaymentCreateFromJson(Map<String, dynamic> json) =>
    PaymentCreate(
      bookingId: json['booking_id'] as String,
      method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
      idempotencyKey: json['idempotency_key'] as String,
    );

Map<String, dynamic> _$PaymentCreateToJson(PaymentCreate instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'idempotency_key': instance.idempotencyKey,
    };
