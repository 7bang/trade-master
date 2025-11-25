import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// 품목 모델
///
/// 자주 거래하는 상품 정보를 나타냅니다.
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String businessId,
    required String name,
    String? code,
    String? category,
    double? defaultUnitPrice,
    @Default('개') String unit,
    String? description,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
