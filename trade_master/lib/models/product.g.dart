// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      category: json['category'] as String?,
      defaultUnitPrice: (json['default_unit_price'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '개',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'name': instance.name,
      'code': instance.code,
      'category': instance.category,
      'default_unit_price': instance.defaultUnitPrice,
      'unit': instance.unit,
      'description': instance.description,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
