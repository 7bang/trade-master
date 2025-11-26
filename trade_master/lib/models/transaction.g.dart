// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      productId: json['product_id'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customer: json['customer'] == null
          ? null
          : Customer.fromJson(json['customer'] as Map<String, dynamic>),
      product: json['product'] == null
          ? null
          : Product.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'customer_id': instance.customerId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'memo': instance.memo,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'customer': instance.customer,
      'product': instance.product,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.receivable: 'receivable',
  TransactionType.payable: 'payable',
};
